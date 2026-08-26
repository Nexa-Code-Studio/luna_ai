from abc import ABC, abstractmethod


class BaseEmbeddingProvider(ABC):
    """Provider-agnostic interface for vector embedding generation."""

    @abstractmethod
    async def embed_query(self, text: str) -> list[float]:
        """Generate embedding vector for a single search query text."""
        pass

    @abstractmethod
    async def embed_documents(self, texts: list[str]) -> list[list[float]]:
        """Generate embedding vectors for a batch of document texts."""
        pass
