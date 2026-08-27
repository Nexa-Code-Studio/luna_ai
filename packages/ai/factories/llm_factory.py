import logging
from typing import ClassVar

from packages.ai.interfaces.llm import BaseLLMProvider
from packages.ai.providers.llm.deepseek_llm import DeepSeekLLMProvider
from packages.ai.providers.llm.gemini_llm import GeminiLLMProvider
from packages.ai.providers.llm.mock_llm import MockLLMProvider
from packages.ai.providers.llm.ollama_llm import OllamaLLMProvider
from packages.ai.providers.llm.openai_llm import OpenAILLMProvider
from packages.shared.config import settings

logger = logging.getLogger(__name__)


def _is_placeholder(key: str | None) -> bool:
    if not key:
        return True
    return key.strip().startswith("your-") or "placeholder" in key.lower()


class LLMFactory:
    """Factory for instantiating LLM providers based on environment configuration."""

    _instances: ClassVar[dict[str, BaseLLMProvider]] = {}

    @classmethod
    def get_provider(
        cls, provider_type: str | None = None, force_new: bool = False
    ) -> BaseLLMProvider:
        target = (provider_type or settings.LLM_PROVIDER or "mock").lower()

        if not force_new and target in cls._instances:
            return cls._instances[target]

        logger.info(f"Instantiating LLM Provider: '{target}'")

        if target in ("deepseek", "deepseek-chat"):
            if _is_placeholder(settings.LLM_API_KEY):
                logger.warning("LLM_API_KEY is empty or placeholder in .env. Falling back to MockLLMProvider.")
                instance = MockLLMProvider()
            else:
                instance = DeepSeekLLMProvider()
        elif target == "openai":
            if _is_placeholder(settings.LLM_API_KEY):
                logger.warning("LLM_API_KEY is empty or placeholder in .env. Falling back to MockLLMProvider.")
                instance = MockLLMProvider()
            else:
                instance = OpenAILLMProvider()
        elif target == "gemini":
            if _is_placeholder(settings.GEMINI_API_KEY) and _is_placeholder(settings.LLM_API_KEY):
                logger.warning("GEMINI_API_KEY is empty or placeholder in .env. Falling back to MockLLMProvider.")
                instance = MockLLMProvider()
            else:
                instance = GeminiLLMProvider()
        elif target == "ollama":
            instance = OllamaLLMProvider()
        elif target == "mock":
            instance = MockLLMProvider()
        else:
            logger.warning(f"Unknown LLM provider '{target}', falling back to MockLLMProvider.")
            instance = MockLLMProvider()

        cls._instances[target] = instance
        return instance
