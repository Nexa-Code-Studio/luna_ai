import logging
from collections.abc import AsyncGenerator

from packages.ai.interfaces.tts import BaseTTSProvider
from packages.shared.config import settings

logger = logging.getLogger(__name__)


class EdgeTTSProvider(BaseTTSProvider):
    """Free Text-to-Speech provider using Microsoft Edge Neural TTS voices with resilient error handling."""

    def __init__(self, default_voice: str | None = None) -> None:
        self.default_voice = default_voice or settings.EDGE_TTS_VOICE or "id-ID-GadisNeural"

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        voice = voice_id or self.default_voice
        try:
            import edge_tts
        except ImportError:
            raise ImportError("edge-tts package is missing. Run pip install edge-tts.")

        clean_text = text.strip()
        if not clean_text or not any(c.isalnum() for c in clean_text):
            return b""

        try:
            communicate = edge_tts.Communicate(clean_text, voice)
            audio_chunks = []
            async for chunk in communicate.stream():
                if chunk["type"] == "audio":
                    audio_chunks.append(chunk["data"])
            return b"".join(audio_chunks)
        except Exception as e:
            logger.warning(f"⚠️ [EDGE-TTS SYNTHESIZE EXCEPTION] Skipped '{clean_text[:30]}...': {e}")
            return b""

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
