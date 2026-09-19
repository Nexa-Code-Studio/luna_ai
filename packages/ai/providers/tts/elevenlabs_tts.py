import logging
from collections.abc import AsyncGenerator
from datetime import date, datetime, timedelta, timezone
from typing import ClassVar

import httpx
from packages.ai.interfaces.tts import BaseTTSProvider
from packages.shared.config import settings

logger = logging.getLogger(__name__)

# Waktu Indonesia Barat (WIB = UTC+7)
WIB = timezone(timedelta(hours=7))


class ElevenLabsTTSProvider(BaseTTSProvider):
    """ElevenLabs TTS Provider with multi-key sequential failover and daily reset."""

    # Class-level shared state across instances so all requests share rotation status
    _shared_exhausted_keys: ClassVar[set[str]] = set()
    _shared_current_key_index: ClassVar[int] = 0
    _shared_last_reset_date: ClassVar[date | None] = None

    def __init__(self, api_key: str | None = None, voice_id: str | None = None) -> None:
        if api_key:
            raw_keys = [k.strip() for k in api_key.split(",") if k.strip()]
        else:
            raw_keys = settings.get_elevenlabs_keys()

        self.keys: list[str] = [
            k for k in raw_keys if k and not k.startswith("your-") and "placeholder" not in k.lower()
        ]
        self.default_voice = voice_id or settings.TTS_VOICE_ID or "cgSgspJ2msm6clMCkdW9"
        self.model_id = settings.TTS_MODEL or "eleven_multilingual_v2"

        self._check_daily_reset()

    @property
    def api_key(self) -> str:
        if self.keys:
            idx = ElevenLabsTTSProvider._shared_current_key_index % len(self.keys)
            return self.keys[idx]
        return ""

    @classmethod
    def _check_daily_reset(cls) -> None:
        """Reset exhausted keys when date in WIB (UTC+7) changes."""
        today_wib = datetime.now(WIB).date()
        if cls._shared_last_reset_date is None or today_wib > cls._shared_last_reset_date:
            if cls._shared_exhausted_keys:
                logger.info(
                    f"🔄 [ELEVENLABS RESET] New day {today_wib} (WIB): "
                    f"Cleared {len(cls._shared_exhausted_keys)} exhausted API keys for fresh quota."
                )
            cls._shared_exhausted_keys.clear()
            cls._shared_current_key_index = 0
            cls._shared_last_reset_date = today_wib

    @staticmethod
    def _mask_key(key: str) -> str:
        if len(key) <= 12:
            return "***"
        return f"{key[:8]}...{key[-4:]}"

    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        self._check_daily_reset()

        if not self.keys:
            logger.warning("No ElevenLabs API keys configured. Falling back to EdgeTTSProvider.")
            from packages.ai.providers.tts.edge_tts_provider import EdgeTTSProvider
            return await EdgeTTSProvider().synthesize(text)

        voice = voice_id or self.default_voice
        url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
        payload = {
            "text": text,
            "model_id": self.model_id,
            "voice_settings": {
                "stability": 0.5,
                "similarity_boost": 0.75,
            },
        }

        attempts = 0
        total_keys = len(self.keys)

        async with httpx.AsyncClient() as client:
            while attempts < total_keys:
                # Find next unexhausted key
                avail_keys = [k for k in self.keys if k not in ElevenLabsTTSProvider._shared_exhausted_keys]
                if not avail_keys:
                    break

                curr_idx = ElevenLabsTTSProvider._shared_current_key_index % total_keys
                current_key = self.keys[curr_idx]

                if current_key in ElevenLabsTTSProvider._shared_exhausted_keys:
                    ElevenLabsTTSProvider._shared_current_key_index = (curr_idx + 1) % total_keys
                    attempts += 1
                    continue

                headers = {
                    "Accept": "audio/mpeg",
                    "Content-Type": "application/json",
                    "xi-api-key": current_key,
                }

                try:
                    response = await client.post(url, json=payload, headers=headers, timeout=30.0)
                    if response.status_code == 200:
                        return response.content

                    # Check for library voice paid plan requirement
                    if response.status_code == 402 and "paid_plan_required" in response.text and voice != "EXAVITQu4vr4xnSDxMaL":
                        logger.warning(
                            f"ElevenLabs library voice '{voice}' requires a paid plan. "
                            "Falling back to premade multilingual voice 'EXAVITQu4vr4xnSDxMaL' (Sarah)."
                        )
                        return await self.synthesize(text, voice_id="EXAVITQu4vr4xnSDxMaL")

                    # Check for quota exceeded or authentication limits
                    resp_text = response.text.lower()
                    is_quota_error = (
                        response.status_code in (401, 402, 429)
                        or "quota_exceeded" in resp_text
                        or "quota" in resp_text
                        or "credit" in resp_text
                    )

                    if is_quota_error:
                        ElevenLabsTTSProvider._shared_exhausted_keys.add(current_key)
                        masked = self._mask_key(current_key)
                        ElevenLabsTTSProvider._shared_current_key_index = (curr_idx + 1) % total_keys
                        remaining = len(self.keys) - len(ElevenLabsTTSProvider._shared_exhausted_keys)
                        logger.warning(
                            f"⚠️ [ELEVENLABS QUOTA EXCEEDED] Key {masked} limit reached "
                            f"(HTTP {response.status_code}: {response.text[:120]}). "
                            f"Rotating to next key ({remaining}/{total_keys} active)."
                        )
                        attempts += 1
                        continue

                    logger.error(
                        f"❌ [ELEVENLABS UNEXPECTED ERROR] HTTP {response.status_code}: {response.text[:150]}"
                    )
                    attempts += 1
                    ElevenLabsTTSProvider._shared_current_key_index = (curr_idx + 1) % total_keys

                except Exception as ex:
                    logger.error(f"⚠️ [ELEVENLABS HTTP EXCEPTION] {ex}")
                    attempts += 1
                    ElevenLabsTTSProvider._shared_current_key_index = (curr_idx + 1) % total_keys

        # All keys exhausted or unavailable for today: Fall back to EdgeTTS
        logger.warning(
            f"🚨 [ELEVENLABS ALL EXHAUSTED] All {total_keys} ElevenLabs API keys have exhausted their quota "
            f"for today ({datetime.now(WIB).date()}). Gracefully falling back to EdgeTTSProvider (Free Indonesian Voice)."
        )
        from packages.ai.providers.tts.edge_tts_provider import EdgeTTSProvider
        return await EdgeTTSProvider().synthesize(text)

    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        full_text = ""
        async for chunk in text_stream:
            full_text += chunk

        if full_text.strip():
            audio_bytes = await self.synthesize(full_text, voice_id=voice_id)
            yield audio_bytes
