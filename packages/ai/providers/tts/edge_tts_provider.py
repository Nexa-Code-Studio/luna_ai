import logging
import math
from collections.abc import AsyncGenerator

from packages.ai.interfaces.tts import BaseTTSProvider
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts
from packages.shared.config import settings

logger = logging.getLogger(__name__)


class EdgeTTSProvider(BaseTTSProvider):
    """Free Text-to-Speech provider using Microsoft Edge Neural TTS voices with resilient error handling."""

    def __init__(self, default_voice: str | None = None) -> None:
        self.default_voice = default_voice or settings.EDGE_TTS_VOICE or "id-ID-GadisNeural"

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        audio, _ = await self.synthesize_with_envelope(text, voice_id)
        return audio

    async def synthesize_with_envelope(
        self, text: str, voice_id: str | None = None
    ) -> tuple[bytes, list[float]]:
        voice = voice_id or self.default_voice
        try:
            import edge_tts
        except ImportError:
            raise ImportError("edge-tts package is missing. Run pip install edge-tts.")

        clean_text = sanitize_text_for_tts(text)
        if not clean_text or not any(c.isalnum() for c in clean_text):
            return b"", []

        try:
            communicate = edge_tts.Communicate(clean_text, voice, boundary="WordBoundary")
            audio_chunks = []
            word_boundaries = []
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_chunks.append(chunk["data"])
                elif chunk["type"] == "WordBoundary":
                    word_boundaries.append(chunk)

            audio_bytes = b"".join(audio_chunks)
            if not audio_bytes or not word_boundaries:
                return audio_bytes, []

            # Generate 50ms time-aligned amplitude envelope
            interval_ms = 50
            last_wb = word_boundaries[-1]
            total_ms = int((last_wb["offset"] + last_wb["duration"]) / 10000) + 100
            sample_count = max(1, total_ms // interval_ms + 1)
            envelope = [0.0] * sample_count

            for wb in word_boundaries:
                start_ms = wb["offset"] / 10000.0
                dur_ms = wb["duration"] / 10000.0
                end_ms = start_ms + dur_ms
                start_idx = max(0, int(start_ms // interval_ms))
                end_idx = min(sample_count, int(end_ms // interval_ms) + 1)

                for i in range(start_idx, end_idx):
                    t_ms = i * interval_ms
                    if start_ms <= t_ms <= end_ms and dur_ms > 0:
                        rel = (t_ms - start_ms) / dur_ms
                        # Natural vocal envelope with attack/decay and syllabic modulation
                        amp = math.sin(rel * math.pi) * 0.85
                        amp += 0.15 * math.sin(rel * math.pi * 3)
                        amp = max(0.15, min(1.0, amp))
                        envelope[i] = max(envelope[i], round(amp, 3))

            return audio_bytes, envelope
        except Exception as e:
            logger.warning(f"⚠️ [EDGE-TTS SYNTHESIZE EXCEPTION] Skipped '{clean_text[:30]}...': {e}")
            return b"", []

    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        voice = voice_id or self.default_voice
        try:
            import edge_tts
        except ImportError:
            raise ImportError("edge-tts package is missing. Run pip install edge-tts.")

        buffer = ""
        async for text_chunk in text_stream:
            buffer += text_chunk
            # When sentence delimiters or enough text is available, synthesize chunk
            if any(punct in buffer for punct in [".", "!", "?", "\n", ", "]) or len(buffer) >= 40:
                clean_text = buffer.strip()
                if clean_text and any(c.isalnum() for c in clean_text):
                    try:
                        communicate = edge_tts.Communicate(clean_text, voice)
                        async for chunk in communicate.stream():
                            if chunk["type"] == "audio":
                                yield chunk["data"]
                    except Exception as e:
                        logger.warning(f"⚠️ [EDGE-TTS STREAM EXCEPTION] Skipped '{clean_text[:30]}...': {e}")
                buffer = ""

        # Flush remaining text in buffer
        clean_text = buffer.strip()
        if clean_text and any(c.isalnum() for c in clean_text):
            try:
                communicate = edge_tts.Communicate(clean_text, voice)
                async for chunk in communicate.stream():
                    if chunk["type"] == "audio":
                        yield chunk["data"]
            except Exception as e:
                logger.warning(f"⚠️ [EDGE-TTS FLUSH EXCEPTION] Skipped '{clean_text[:30]}...': {e}")
