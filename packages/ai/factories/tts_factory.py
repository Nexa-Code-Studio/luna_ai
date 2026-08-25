import logging
from typing import ClassVar

from packages.ai.interfaces.tts import BaseTTSProvider
from packages.ai.providers.tts.elevenlabs_tts import ElevenLabsTTSProvider
from packages.ai.providers.tts.mock_tts import MockTTSProvider
from packages.ai.providers.tts.openai_tts import OpenAITTSProvider
from packages.shared.config import settings

logger = logging.getLogger(__name__)


def _is_placeholder(key: str | None) -> bool:
    if not key:
        return True
    return key.strip().startswith("your-") or "placeholder" in key.lower()


class TTSFactory:
    """Factory for instantiating TTS providers based on environment configuration."""

    _instances: ClassVar[dict[str, BaseTTSProvider]] = {}

    @classmethod
    def get_provider(
        cls, provider_type: str | None = None, force_new: bool = False
    ) -> BaseTTSProvider:
        target = (provider_type or settings.TTS_PROVIDER or "mock").lower()

        if not force_new and target in cls._instances:
            return cls._instances[target]

        logger.info(f"Instantiating TTS Provider: '{target}'")

        if target == "elevenlabs":
            if _is_placeholder(settings.TTS_API_KEY):
                logger.warning("TTS_API_KEY is empty or placeholder in .env. Falling back to MockTTSProvider.")
                instance = MockTTSProvider()
            else:
                instance = ElevenLabsTTSProvider()
        elif target == "openai":
            if _is_placeholder(settings.TTS_API_KEY) and _is_placeholder(settings.LLM_API_KEY):
                logger.warning("TTS_API_KEY / LLM_API_KEY is empty or placeholder in .env. Falling back to MockTTSProvider.")
                instance = MockTTSProvider()
            else:
                instance = OpenAITTSProvider()
        elif target == "mock":
            instance = MockTTSProvider()
        else:
            logger.warning(f"Unknown TTS provider '{target}', falling back to MockTTSProvider.")
            instance = MockTTSProvider()

        cls._instances[target] = instance
        return instance
