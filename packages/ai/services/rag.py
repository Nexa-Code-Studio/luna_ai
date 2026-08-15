from typing import Any

from ai.interfaces.vector_store import BaseVectorStore, VectorDocument


class RAGService:
    """High-level RAG service encapsulating vector store interactions."""

    def __init__(self, vector_store: BaseVectorStore):
        self.vector_store = vector_store

    async def search_relevant_context(
        self,
        collection_name: str,
        query_embedding: list[float],
        limit: int = 5,
    ) -> list[dict[str, Any]]:
        """Search relevant document payloads using vector store interface."""
        documents: list[VectorDocument] = await self.vector_store.search(
            collection_name=collection_name,
            query_vector=query_embedding,
            limit=limit,
        )
        return [doc.payload for doc in documents]
