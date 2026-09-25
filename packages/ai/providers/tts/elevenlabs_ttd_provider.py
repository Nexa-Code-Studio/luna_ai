from __future__ import annotations

import asyncio
import base64
import json
import logging
from datetime import date, datetime, timedelta, timezone
from typing import Any, AsyncGenerator, ClassVar

try:
    import websockets
    from websockets.exceptions import ConnectionClosed
except ImportError:
    websockets = None  # type: ignore[assignment]
    ConnectionClosed = Exception  # type: ignore[assignment,misc]

from packages.ai.interfaces.tts import BaseTTSProvider
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts
from packages.shared.config import settings

logger = logging.getLogger(__name__)

# Waktu Indonesia Barat (WIB = UTC+7)
WIB = timezone(timedelta(hours=7))


class ElevenLabsTTDSession:
    """Asynchronous bidirectional Text-to-Dialogue (TTD) streaming session for ElevenLabs v3."""

    def __init__(
        self,
        api_key: str,
        voice_id: str,
        model_id: str = "eleven_v3_conversational",
        output_format: str = "mp3_44100_128",
        keys: list[str] | None = None,
    ) -> None:
        self.api_key = api_key
        self.keys = keys or ([api_key] if api_key else [])
        self.voice_id = voice_id
        # Text-to-Dialogue WebSocket API strictly requires an eleven_v3 model
        if not model_id.startswith("eleven_v3"):
            self.model_id = "eleven_v3_conversational"
        else:
            self.model_id = model_id
        self.output_format = output_format
        self.ws: websockets.client.WebSocketClientProtocol | None = None
        self._event_queue: asyncio.Queue[tuple[str, Any] | None] = asyncio.Queue()
        self._recv_task: asyncio.Task[None] | None = None
        self._is_closed = False
        self._total_audio_bytes_received = 0
        self._error: Exception | None = None

    @property
    def url(self) -> str:
        base = getattr(settings, "ELEVENLABS_TTD_URL", "wss://api.elevenlabs.io/v1/text-to-dialogue/stream-input")
        return f"{base}?model_id={self.model_id}&output_format={self.output_format}"

    async def connect(self, timeout: float = 8.0) -> None:
        if websockets is None:
            raise RuntimeError("websockets package is not installed")

        candidate_keys = self.keys if self.keys else [self.api_key]
        last_ex: Exception | None = None

        for attempt in range(len(candidate_keys)):
            current_key = ElevenLabsTTDProvider.get_active_key(candidate_keys)
            self.api_key = current_key
            headers = {"xi-api-key": current_key}
            logger.info(
                f"🔌 [ELEVENLABS TTD CONNECTING] Attempt {attempt + 1}/{len(candidate_keys)} | "
                f"Key: ...{current_key[-6:] if len(current_key) >= 6 else current_key} | "
                f"Model: {self.model_id} | Voice: {self.voice_id}"
            )

            try:
                self.ws = await asyncio.wait_for(
                    websockets.connect(self.url, additional_headers=headers),
                    timeout=timeout,
                )

                # Step 1: Handshake frame registering the voice
                init_frame = {"voices": [self.voice_id]}
                await self.ws.send(json.dumps(init_frame))
                logger.info(f"✅ [ELEVENLABS TTD INITIALIZED] Registered voice '{self.voice_id}' with key ...{current_key[-6:]}")

                # Start receiver worker concurrently
                self._recv_task = asyncio.create_task(self._receive_loop())
                return
            except Exception as ex:
                last_ex = ex
                err_str = str(ex).lower()
                if "401" in err_str or "403" in err_str or "429" in err_str or "policy violation" in err_str:
                    logger.warning(f"⚠️ [ELEVENLABS TTD KEY FAILED] Key ...{current_key[-6:]} rejected ({ex}). Rotating to next key...")
                    ElevenLabsTTDProvider.mark_key_exhausted(current_key)
                else:
                    logger.error(f"❌ [ELEVENLABS TTD CONNECT ERROR] {ex}")
                    raise

        if last_ex:
            raise last_ex

    async def send_text(self, text: str, new_turn: bool = False) -> None:
        if not self.ws or self._is_closed:
            raise RuntimeError("Cannot send text: TTD WebSocket is not connected or already closed")

        clean = sanitize_text_for_tts(text)
        if not clean:
            return

        frame = {
            "inputs": [
                {
                    "text": clean,
                    "voice_id": self.voice_id,
                    "new_turn": new_turn,
                }
            ]
        }
        await self.ws.send(json.dumps(frame))
        logger.debug(f"📤 [ELEVENLABS TTD SENT] '{clean}' (new_turn={new_turn})")

    async def flush(self) -> None:
        """Force synthesis of any buffered text."""
        if self.ws and not self._is_closed:
            await self.ws.send(json.dumps({"flush": True}))
            logger.debug("⚡ [ELEVENLABS TTD FLUSH SENT]")

    async def finish(self) -> None:
        """Signal turn completion and close socket on ElevenLabs server side."""
        if self.ws and not self._is_closed:
            try:
                await self.ws.send(json.dumps({"flush": True}))
                await self.ws.send(json.dumps({"close_socket": True}))
                logger.debug("🏁 [ELEVENLABS TTD CLOSE_SOCKET SENT]")
            except Exception as e:
                logger.warning(f"⚠️ [ELEVENLABS TTD FINISH EXCEPTION] {e}")

    async def _receive_loop(self) -> None:
        """Background loop reading audio chunks and boundary markers from ElevenLabs."""
        try:
            while not self._is_closed and self.ws:
                raw_msg = await self.ws.recv()
                data = json.loads(raw_msg)

                # 1. Incoming partial audio
                if "audio" in data and data["audio"]:
                    raw_bytes = base64.b64decode(data["audio"])
                    if raw_bytes:
                        self._total_audio_bytes_received += len(raw_bytes)
                        await self._event_queue.put(("audio", raw_bytes))

                # 2. Turn audio complete marker
                if data.get("is_final_audio_for_turn"):
                    logger.debug("🏁 [ELEVENLABS TTD TURN AUDIO COMPLETE]")
                    await self._event_queue.put(("turn_complete", None))

                # 3. Final session closing marker
                if data.get("is_final"):
                    logger.debug("🔚 [ELEVENLABS TTD SESSION FINALIZED]")
                    await self._event_queue.put(("session_final", None))
                    break

                # 4. Error payload
                if "error" in data:
                    err_msg = data.get("message") or str(data)
                    logger.error(f"❌ [ELEVENLABS TTD SERVER ERROR]: {err_msg}")
                    err_lower = err_msg.lower()
                    if "quota" in err_lower or "credit" in err_lower or "exceed" in err_lower or "limit" in err_lower:
                        ElevenLabsTTDProvider.mark_key_exhausted(self.api_key)
                    self._error = RuntimeError(f"ElevenLabs error: {err_msg}")
                    await self._event_queue.put(("error", self._error))
                    break

        except ConnectionClosed as cc:
            logger.info(f"🔌 [ELEVENLABS TTD SOCKET CLOSED] Code: {cc.code}")
        except asyncio.CancelledError:
            logger.info("⚡ [ELEVENLABS TTD RECV CANCELLED]")
        except Exception as ex:
            logger.error(f"❌ [ELEVENLABS TTD RECV EXCEPTION]: {ex}")
            self._error = ex
            await self._event_queue.put(("error", ex))
        finally:
            await self._event_queue.put(None)  # Sentinel to unblock consumers

    async def stream_sentence_audio(
        self, speech_chunks: AsyncGenerator[Any, None]
    ) -> AsyncGenerator[tuple[Any, bytes], None]:
        """Pipe incoming SpeechChunks to TTD sender, and yield (chunk, sentence_audio_bytes) as each completes."""
        chunks_in_flight: list[Any] = []

        async def _sender():
            try:
                async for chunk in speech_chunks:
                    chunks_in_flight.append(chunk)
                    await self.send_text(chunk.tts_text, new_turn=False)
                    await self.flush()
                await self.finish()
            except Exception as ex:
                logger.error(f"⚠️ [TTD SENDER ERROR] {ex}")

        sender_task = asyncio.create_task(_sender())

        chunk_idx = 0
        current_audio_parts: list[bytes] = []

        try:
            while True:
                item = await self._event_queue.get()
                if item is None:
                    break

                event_type, payload = item

                if event_type == "audio":
                    current_audio_parts.append(payload)

                elif event_type == "turn_complete":
                    if current_audio_parts:
                        sentence_bytes = b"".join(current_audio_parts)
                        current_audio_parts = []
                        if chunk_idx < len(chunks_in_flight):
                            ref_chunk = chunks_in_flight[chunk_idx]
                            chunk_idx += 1
                        else:
                            ref_chunk = None

                        yield ref_chunk, sentence_bytes

                elif event_type == "session_final":
                    # Flush any remaining audio
                    if current_audio_parts:
                        sentence_bytes = b"".join(current_audio_parts)
                        current_audio_parts = []
                        ref_chunk = chunks_in_flight[chunk_idx] if chunk_idx < len(chunks_in_flight) else None
                        yield ref_chunk, sentence_bytes
                    break

                elif event_type == "error":
                    raise payload

            await sender_task
        except Exception:
            sender_task.cancel()
            raise

    async def receive_audio_chunks(self) -> AsyncGenerator[bytes, None]:
        """Async generator yielding raw audio bytes as they arrive from ElevenLabs."""
        while True:
            item = await self._event_queue.get()
            if item is None:
                break
            event_type, payload = item
            if event_type == "audio":
                yield payload
            elif event_type == "session_final":
                break
            elif event_type == "error":
                raise payload

    async def close(self) -> None:
        """Clean up connection and background tasks."""
        self._is_closed = True
        if self._recv_task and not self._recv_task.done():
            self._recv_task.cancel()
            try:
                await self._recv_task
            except asyncio.CancelledError:
                pass

        if self.ws:
            try:
                await self.ws.close()
            except Exception:
                pass
            self.ws = None


class ElevenLabsTTDProvider(BaseTTSProvider):
    """Text-to-Speech provider using ElevenLabs Text-to-Dialogue (TTD) WebSocket API for Eleven v3."""

    _shared_exhausted_keys: ClassVar[set[str]] = set()
    _shared_current_key_index: ClassVar[int] = 0
    _shared_last_reset_date: ClassVar[date | None] = None

    def __init__(
        self,
        api_key: str | None = None,
        voice_id: str | None = None,
        model_id: str | None = None,
    ) -> None:
        if api_key:
            raw_keys = [k.strip() for k in api_key.split(",") if k.strip()]
        else:
            raw_keys = settings.get_elevenlabs_keys()

        self.keys: list[str] = [
            k for k in raw_keys if k and not k.startswith("your-") and "placeholder" not in k.lower()
        ]
        self.voice_id = voice_id or settings.TTS_VOICE_ID or "cgSgspJ2msm6clMCkdW9"

        # Enforce eleven_v3 model for TTD WebSocket
        configured_model = model_id or getattr(settings, "TTS_MODEL", "eleven_v3_conversational")
        if configured_model and configured_model.startswith("eleven_v3"):
            self.model_id = configured_model
        else:
            self.model_id = "eleven_v3_conversational"

        self.output_format = getattr(settings, "ELEVENLABS_OUTPUT_FORMAT", "mp3_44100_128")
        self._check_daily_reset()

    @property
    def api_key(self) -> str:
        return self.get_active_key(self.keys)

    @classmethod
    def _check_daily_reset(cls) -> None:
        today_wib = datetime.now(WIB).date()
        if cls._shared_last_reset_date is None or today_wib > cls._shared_last_reset_date:
            if cls._shared_exhausted_keys:
                logger.info(
                    f"🔄 [ELEVENLABS TTD RESET] New day {today_wib} (WIB): "
                    f"Cleared {len(cls._shared_exhausted_keys)} exhausted API keys for fresh quota."
                )
            cls._shared_exhausted_keys.clear()
            cls._shared_current_key_index = 0
            cls._shared_last_reset_date = today_wib

    @classmethod
    def mark_key_exhausted(cls, key: str) -> None:
        if key not in cls._shared_exhausted_keys:
            cls._shared_exhausted_keys.add(key)
            logger.warning(
                f"⚠️ [ELEVENLABS TTD KEY EXHAUSTED] Marked key ...{key[-6:] if len(key) >= 6 else key} as exhausted. "
                f"Total exhausted: {len(cls._shared_exhausted_keys)}"
            )
            cls._shared_current_key_index += 1

    @classmethod
    def get_active_key(cls, keys: list[str]) -> str:
        if not keys:
            return ""
        for i in range(len(keys)):
            idx = (cls._shared_current_key_index + i) % len(keys)
            candidate = keys[idx]
            if candidate not in cls._shared_exhausted_keys:
                cls._shared_current_key_index = idx
                return candidate
        return keys[cls._shared_current_key_index % len(keys)]

    def create_session(self, voice_id: str | None = None) -> ElevenLabsTTDSession:
        return ElevenLabsTTDSession(
            api_key=self.api_key,
            voice_id=voice_id or self.voice_id,
            model_id=self.model_id,
            output_format=self.output_format,
            keys=self.keys,
        )

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        """Synthesize text into complete audio bytes using a turn-scoped TTD session with key retry."""
        candidate_keys = self.keys if self.keys else [self.api_key]
        last_error: Exception | None = None
        for _ in range(len(candidate_keys)):
            session = self.create_session(voice_id=voice_id)
            try:
                await session.connect()
                await session.send_text(text)
                await session.finish()

                chunks: list[bytes] = []
                async for chunk in session.receive_audio_chunks():
                    chunks.append(chunk)

                if session._error and not chunks:
                    raise session._error

                if chunks:
                    return b"".join(chunks)
            except Exception as e:
                last_error = e
                err_str = str(e).lower()
                if "quota" in err_str or "credit" in err_str or "exceed" in err_str or "403" in err_str:
                    logger.warning(
                        f"⚠️ [ELEVENLABS TTD SYNTHESIS QUOTA EXCEEDED] Key ...{session.api_key[-6:]} exhausted ({e}). Retrying with next key..."
                    )
                    self.mark_key_exhausted(session.api_key)
                else:
                    raise
            finally:
                await session.close()

        if last_error:
            raise last_error
        return b""

    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        """Stream text tokens through TTD WebSocket and yield audio chunks concurrently."""
        session = self.create_session(voice_id=voice_id)
        try:
            await session.connect()

            # Concurrent producer task
            async def _sender():
                try:
                    async for token in text_stream:
                        await session.send_text(token)
                    await session.finish()
                except Exception as ex:
                    logger.error(f"Error in TTD stream sender: {ex}")

            sender_task = asyncio.create_task(_sender())

            async for chunk in session.receive_audio_chunks():
                yield chunk

            await sender_task
        finally:
            await session.close()
