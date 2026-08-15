from abc import ABC, abstractmethod
from collections.abc import AsyncGenerator
from typing import Any

from pydantic import BaseModel


class LLMMessage(BaseModel):
    role: str  # "system", "user", "assistant", "tool"
    content: str
    name: str | None = None


class BaseLLMProvider(ABC):
    """Provider-agnostic interface for Large Language Models."""

    @abstractmethod
    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        **kwargs: Any,
    ) -> str:
        """Generate complete LLM response."""
        pass

    @abstractmethod
    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        """Stream LLM response tokens."""
        pass
