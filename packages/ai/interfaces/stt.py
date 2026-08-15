from abc import ABC, abstractmethod
from collections.abc import AsyncGenerator


class BaseSTTProvider(ABC):
    """Provider-agnostic interface for Speech-To-Text services."""

    @abstractmethod
    async def transcribe_audio(self, audio_bytes: bytes, sample_rate: int = 16000) -> str:
        """Transcribe complete audio payload into text."""
        pass

    @abstractmethod
    async def transcribe_stream(
        self, audio_stream: AsyncGenerator[bytes, None]
    ) -> AsyncGenerator[str, None]:
        """Stream audio chunks and yield real-time transcripts."""
        pass
