from abc import ABC, abstractmethod
from collections.abc import AsyncGenerator


class BaseTTSProvider(ABC):
    """Provider-agnostic interface for Text-To-Speech services."""

    @abstractmethod
    async def synthesize(self, text: str, voice_id: str | None = None) -> bytes:
        """Synthesize text into complete audio bytes."""
        pass

    @abstractmethod
    async def synthesize_stream(
        self, text_stream: AsyncGenerator[str, None], voice_id: str | None = None
    ) -> AsyncGenerator[bytes, None]:
        """Stream text tokens into real-time audio chunks."""
        pass
