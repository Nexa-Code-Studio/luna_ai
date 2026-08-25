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
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        """Generate complete LLM response.
        
        Args:
            messages: List of system, user, assistant messages.
            temperature: Sampling temperature (0.0 to 1.0).
            response_format: Output format, e.g. "json" / "text" or provider-specific dict.
            **kwargs: Extra provider-specific parameters.
        """
        pass

    @abstractmethod
    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        """Stream LLM response tokens."""
        pass
