from abc import ABC, abstractmethod
from typing import Any

from pydantic import BaseModel


class VectorDocument(BaseModel):
    id: str
    vector: list[float]
    payload: dict[str, Any]


class BaseVectorStore(ABC):
    """Provider-agnostic interface for Vector Store engines (Qdrant, etc.)."""

    @abstractmethod
    async def create_collection(self, collection_name: str, vector_size: int) -> bool:
        """Initialize collection/index."""
        pass

    @abstractmethod
    async def upsert(self, collection_name: str, documents: list[VectorDocument]) -> bool:
        """Upsert documents into collection."""
        pass

    @abstractmethod
    async def search(
        self,
        collection_name: str,
        query_vector: list[float],
        limit: int = 5,
    ) -> list[VectorDocument]:
        """Perform similarity search."""
        pass
