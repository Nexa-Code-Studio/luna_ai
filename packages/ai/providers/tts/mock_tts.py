import asyncio
import struct
from collections.abc import AsyncGenerator

from packages.ai.interfaces.tts import BaseTTSProvider


class MockTTSProvider(BaseTTSProvider):
    """Mock TTS Provider generating local synthetic audio bytes without external API keys."""

    def _generate_wav_header(self, data_size: int = 1000) -> bytes:
        sample_rate = 16000
        bits_per_sample = 16
        channels = 1
        byte_rate = sample_rate * channels * (bits_per_sample // 8)
        block_align = channels * (bits_per_sample // 8)
        
        header = struct.pack(
            '<4sI4s4sIHHIIHH4sI',
            b'RIFF',
            36 + data_size,
            b'WAVE',
            b'fmt ',
            16,
            1,  # PCM
            channels,
            sample_rate,
            byte_rate,
            block_align,
            bits_per_sample,
            b'data',
            data_size,
        )
        return header

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        await asyncio.sleep(0.1)
        data = b'\x00\x00' * 500
        return self._generate_wav_header(len(data)) + data

    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        yield self._generate_wav_header(2000)
        async for chunk in text_stream:
            yield b'\x00\x00' * (len(chunk) * 10)
            await asyncio.sleep(0.05)
