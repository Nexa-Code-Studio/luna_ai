"""
Standalone Unit and Integration Contract Tests for ElevenLabs TTD Provider.
Tests run using standard library unittest (no external pytest dependency required).
"""

import asyncio
import base64
import json
import unittest
from unittest.mock import patch

from packages.ai.providers.tts.elevenlabs_ttd_provider import (
    ElevenLabsTTDProvider,
    ElevenLabsTTDSession,
    validate_ttd_model,
)
from packages.ai.utils.emotion_style_mapper import filter_voice_settings_for_model
from packages.ai.utils.sentence_chunker import SpeechChunk


class MockWebSocket:
    """Mock WebSocket for testing ElevenLabs TTD protocol frames and lifecycle."""

    def __init__(self, incoming_messages: list[dict] | None = None):
        self.sent_frames: list[dict] = []
        self.raw_sent: list[str] = []
        self._recv_queue: asyncio.Queue[str] = asyncio.Queue()
        self.is_closed = False

        if incoming_messages:
            for msg in incoming_messages:
                self._recv_queue.put_nowait(json.dumps(msg))

    async def send(self, data: str) -> None:
        if self.is_closed:
            raise RuntimeError("WebSocket is closed")
        self.raw_sent.append(data)
        parsed = json.loads(data)
        self.sent_frames.append(parsed)

    async def recv(self) -> str:
        if self.is_closed and self._recv_queue.empty():
            from websockets.exceptions import ConnectionClosedOK
            raise ConnectionClosedOK(rcvd=None, sent=None)
        return await self._recv_queue.get()

    async def enqueue_message(self, msg: dict) -> None:
        await self._recv_queue.put(json.dumps(msg))

    async def close(self) -> None:
        self.is_closed = True


class TestElevenLabsTTDContract(unittest.IsolatedAsyncioTestCase):
    """Verifies ElevenLabs TTD v4 Turbo contract adherence, frame sequencing, and lifecycle."""

    def test_model_validation(self):
        """eleven_v4_turbo, eleven_v4, eleven_v3 are valid; unknown models fallback to eleven_v4_turbo."""
        self.assertEqual(validate_ttd_model("eleven_v4_turbo"), "eleven_v4_turbo")
        self.assertEqual(validate_ttd_model("eleven_v4"), "eleven_v4")
        self.assertEqual(validate_ttd_model("eleven_v3_conversational"), "eleven_v3_conversational")
        self.assertEqual(validate_ttd_model("eleven_multilingual_v2"), "eleven_v4_turbo")
        self.assertEqual(validate_ttd_model(None), "eleven_v4_turbo")

    def test_voice_settings_filtering_v4(self):
        """v4 models must strictly discard 'style' and 'speed', clamping stability and similarity_boost."""
        raw_settings = {
            "stability": 1.5,
            "similarity_boost": -0.2,
            "style": 0.6,
            "speed": 1.1,
            "use_speaker_boost": True,
        }
        filtered = filter_voice_settings_for_model("eleven_v4_turbo", raw_settings)
        self.assertIsNotNone(filtered)
        self.assertNotIn("style", filtered)
        self.assertNotIn("speed", filtered)
        self.assertEqual(filtered["stability"], 1.0)
        self.assertEqual(filtered["similarity_boost"], 0.0)
        self.assertTrue(filtered["use_speaker_boost"])

    def test_voice_settings_filtering_v3(self):
        """v3 models retain custom parameters without v4 filtering."""
        raw_settings = {"stability": 0.5, "similarity_boost": 0.8, "style": 0.2}
        filtered = filter_voice_settings_for_model("eleven_v3_conversational", raw_settings)
        self.assertEqual(filtered, raw_settings)

    async def test_handshake_frame_single_voice_and_settings(self):
        """Initial frame must send single voice ID and clamped voice settings."""
        mock_ws = MockWebSocket(incoming_messages=[{"is_final": True}])

        with patch("packages.ai.providers.tts.elevenlabs_ttd_provider.websockets.connect", new=unittest.mock.AsyncMock(return_value=mock_ws)):
            session = ElevenLabsTTDSession(
                api_key="sk_test_12345",
                voice_id="cgSgspJ2msm6clMCkdW9",
                model_id="eleven_v4_turbo",
                voice_settings={"stability": 0.45, "similarity_boost": 0.85, "style": 0.5},
            )
            await session.connect()

            # First sent frame must be the handshake frame
            self.assertGreaterEqual(len(mock_ws.sent_frames), 1)
            init_frame = mock_ws.sent_frames[0]
            self.assertEqual(init_frame["voices"], ["cgSgspJ2msm6clMCkdW9"])
            self.assertIn("voice_settings", init_frame)
            self.assertEqual(init_frame["voice_settings"]["stability"], 0.45)
            self.assertEqual(init_frame["voice_settings"]["similarity_boost"], 0.85)
            self.assertNotIn("style", init_frame["voice_settings"])

            await session.close()

    async def test_new_turn_flag_sequencing_in_multi_chunks(self):
        """new_turn must be True ONLY on the first chunk of a turn, and False on subsequent chunks."""
        mock_ws = MockWebSocket()

        with patch("packages.ai.providers.tts.elevenlabs_ttd_provider.websockets.connect", new=unittest.mock.AsyncMock(return_value=mock_ws)):
            session = ElevenLabsTTDSession(
                api_key="sk_test_12345",
                voice_id="cgSgspJ2msm6clMCkdW9",
                model_id="eleven_v4_turbo",
            )
            await session.connect()

            async def sample_chunks():
                yield SpeechChunk("Halo apa kabar?", "Halo apa kabar?", "neutral", sequence=1, is_first=True, is_final=False)
                yield SpeechChunk("Aku senang bisa ngobrol.", "Aku senang bisa ngobrol.", "neutral", sequence=2, is_first=False, is_final=False)
                yield SpeechChunk("Ada yang mau diceritakan?", "Ada yang mau diceritakan?", "neutral", sequence=3, is_first=False, is_final=True)

            # Consume stream_sentence_audio concurrently while enqueuing server events
            async def feed_server_events():
                # Wait for frames to be sent
                while len(mock_ws.sent_frames) < 4:  # 1 init + 3 chunks
                    await asyncio.sleep(0.01)
                # Emit audio and markers
                dummy_audio = base64.b64encode(b"RIFF_AUDIO_DATA_CHUNK").decode("utf-8")
                await mock_ws.enqueue_message({"audio": dummy_audio})
                await mock_ws.enqueue_message({"is_final_audio_for_turn": True})
                await mock_ws.enqueue_message({"is_final": True})

            feed_task = asyncio.create_task(feed_server_events())
            collected = []
            async for chunk, audio in session.stream_sentence_audio(sample_chunks()):
                collected.append((chunk, audio))
            await feed_task

            # Frame 0: handshake
            # Frame 1: chunk 1 -> new_turn must be True
            # Frame 2: chunk 2 -> new_turn must be False
            # Frame 3: chunk 3 -> new_turn must be False
            # Frame 4: flush
            # Frame 5: close_socket
            self.assertGreaterEqual(len(mock_ws.sent_frames), 6)

            chunk1_frame = mock_ws.sent_frames[1]
            self.assertEqual(chunk1_frame["inputs"][0]["new_turn"], True)
            self.assertEqual(chunk1_frame["inputs"][0]["voice_id"], "cgSgspJ2msm6clMCkdW9")

            chunk2_frame = mock_ws.sent_frames[2]
            self.assertEqual(chunk2_frame["inputs"][0]["new_turn"], False)

            chunk3_frame = mock_ws.sent_frames[3]
            self.assertEqual(chunk3_frame["inputs"][0]["new_turn"], False)

            flush_frame = mock_ws.sent_frames[4]
            self.assertEqual(flush_frame, {"flush": True})

            close_frame = mock_ws.sent_frames[5]
            self.assertEqual(close_frame, {"close_socket": True})

            await session.close()

    async def test_short_phrase_flush_and_finalization(self):
        """Short phrase (15-30 chars) must flush completely and receive audio."""
        mock_ws = MockWebSocket()

        with patch("packages.ai.providers.tts.elevenlabs_ttd_provider.websockets.connect", new=unittest.mock.AsyncMock(return_value=mock_ws)):
            session = ElevenLabsTTDSession(
                api_key="sk_test_12345",
                voice_id="cgSgspJ2msm6clMCkdW9",
                model_id="eleven_v4_turbo",
            )
            await session.connect()

            async def short_chunk_gen():
                # 18 chars
                yield SpeechChunk("Aku dengerin, kok.", "Aku dengerin, kok.", "neutral", sequence=1, is_first=True, is_final=True)

            async def feed_server_events():
                while len(mock_ws.sent_frames) < 2:  # init + chunk
                    await asyncio.sleep(0.01)
                audio_b64 = base64.b64encode(b"SHORT_AUDIO").decode("utf-8")
                await mock_ws.enqueue_message({"audio": audio_b64})
                await mock_ws.enqueue_message({"is_final_audio_for_turn": True})
                await mock_ws.enqueue_message({"is_final": True})

            feed_task = asyncio.create_task(feed_server_events())
            collected = []
            async for chunk, audio in session.stream_sentence_audio(short_chunk_gen()):
                collected.append((chunk, audio))
            await feed_task

            self.assertEqual(len(collected), 1)
            self.assertEqual(collected[0][1], b"SHORT_AUDIO")
            self.assertEqual(collected[0][0].display_text, "Aku dengerin, kok.")

            # Verify flush and close_socket were dispatched
            self.assertTrue(any(f == {"flush": True} for f in mock_ws.sent_frames))
            self.assertTrue(any(f == {"close_socket": True} for f in mock_ws.sent_frames))

            await session.close()

    async def test_telemetry_capture(self):
        """Telemetry must correctly record duration, TTFA, characters sent, and audio bytes."""
        mock_ws = MockWebSocket()

        with patch("packages.ai.providers.tts.elevenlabs_ttd_provider.websockets.connect", new=unittest.mock.AsyncMock(return_value=mock_ws)):
            session = ElevenLabsTTDSession(
                api_key="sk_test_12345",
                voice_id="cgSgspJ2msm6clMCkdW9",
                model_id="eleven_v4_turbo",
            )
            await session.connect()

            audio_payload = b"TELEMETRY_SAMPLE_AUDIO_BYTES"
            audio_b64 = base64.b64encode(audio_payload).decode("utf-8")

            async def feed_server_events():
                await asyncio.sleep(0.02)
                await mock_ws.enqueue_message({"audio": audio_b64})
                await mock_ws.enqueue_message({"is_final_audio_for_turn": True})
                await mock_ws.enqueue_message({"is_final": True})

            feed_task = asyncio.create_task(feed_server_events())
            await session.send_text("Semoga harimu menyenangkan.", new_turn=True)
            await session.finish()

            # Wait for event processing
            while session.telemetry["total_audio_bytes"] == 0:
                await asyncio.sleep(0.01)
            await feed_task

            await session.close()

            self.assertEqual(session.telemetry["input_frames_count"], 1)
            self.assertEqual(session.telemetry["total_chars_sent"], len("Semoga harimu menyenangkan."))
            self.assertEqual(session.telemetry["total_audio_bytes"], len(audio_payload))
            self.assertIsNotNone(session.telemetry["first_audio_ms"])
            self.assertGreater(session.telemetry["first_audio_ms"], 0)
            self.assertIsNotNone(session.telemetry["total_duration_ms"])
            self.assertGreater(session.telemetry["total_duration_ms"], 0)

    async def test_server_error_and_key_rotation_trigger(self):
        """Server quota error marks active key as exhausted and sets session error."""
        mock_ws = MockWebSocket()

        with patch("packages.ai.providers.tts.elevenlabs_ttd_provider.websockets.connect", new=unittest.mock.AsyncMock(return_value=mock_ws)):
            test_key = "sk_exhausted_key_999"
            session = ElevenLabsTTDSession(
                api_key=test_key,
                voice_id="cgSgspJ2msm6clMCkdW9",
                model_id="eleven_v4_turbo",
            )
            await session.connect()

            await mock_ws.enqueue_message({
                "error": "quota_exceeded",
                "message": "Monthly credit quota exceeded",
            })

            # Wait for receive loop to process error
            await asyncio.sleep(0.05)
            self.assertIn(test_key, ElevenLabsTTDProvider._shared_exhausted_keys)
            self.assertIsNotNone(session._error)

            await session.close()


if __name__ == "__main__":
    unittest.main()
