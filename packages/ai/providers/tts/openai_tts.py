from collections.abc import AsyncGenerator

from packages.ai.interfaces.tts import BaseTTSProvider
from packages.shared.config import settings


class OpenAITTSProvider(BaseTTSProvider):
    """OpenAI TTS Provider using Audio Speech API."""

    def __init__(self, api_key: str | None = None, voice_id: str | None = None) -> None:
        self.api_key = api_key or settings.TTS_API_KEY or settings.LLM_API_KEY
        self.default_voice = voice_id or settings.TTS_VOICE_ID or "alloy"
        self._client = None
        if self.api_key:
            try:
                import openai
                self._client = openai.AsyncOpenAI(api_key=self.api_key)
            except ImportError:
                pass

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        try:
            import openai
        except ImportError:
            raise ImportError("openai package is missing. Run pip install openai.")

        if not self.api_key:
            raise ValueError("OpenAI API Key is missing. Check TTS_API_KEY / LLM_API_KEY in .env.")

        if not self._client:
            self._client = openai.AsyncOpenAI(api_key=self.api_key)

        voice = voice_id or self.default_voice
        response = await self._client.audio.speech.create(
            model="tts-1",
            voice=voice,  # type: ignore
            input=text,
        )
        return response.content

    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        full_text = ""
        async for chunk in text_stream:
            full_text += chunk
        
        if full_text.strip():
            audio_bytes = await self.synthesize(full_text, voice_id=voice_id)
            yield audio_bytes
