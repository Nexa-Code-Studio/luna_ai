from collections.abc import AsyncGenerator

import httpx
from packages.ai.interfaces.tts import BaseTTSProvider
from packages.shared.config import settings


class ElevenLabsTTSProvider(BaseTTSProvider):
    """ElevenLabs TTS Provider."""

    def __init__(self, api_key: str | None = None, voice_id: str | None = None) -> None:
        self.api_key = api_key or settings.TTS_API_KEY
        self.default_voice = voice_id or settings.TTS_VOICE_ID or "21m00Tcm4TlvDq8ikWAM"
        self.model_id = settings.TTS_MODEL or "eleven_monolingual_v1"

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        if not self.api_key:
            raise ValueError("ElevenLabs API Key is missing. Check TTS_API_KEY in .env.")

        voice = voice_id or self.default_voice
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
        headers = {
            "Accept": "audio/mpeg",
            "Content-Type": "application/json",
            "xi-api-key": self.api_key,
        }
        payload = {
            "text": text,
            "model_id": self.model_id,
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75,
            },
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(url, json=payload, headers=headers, timeout=30.0)
            if response.status_code != 200:
                raise RuntimeError(f"ElevenLabs TTS API error {response.status_code}: {response.text}")
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
