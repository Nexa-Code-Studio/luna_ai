import logging
from typing import Any, Dict, List, Optional

from ai.interfaces.embedding import BaseEmbeddingProvider
from ai.interfaces.vector_store import BaseVectorStore, VectorDocument
from shared.domain_types import MentalHealthKnowledgeItem

logger = logging.getLogger(__name__)


class KnowledgeIngestionService:
    """
    Qdrant Ingestion & Retrieval Service for Mental Health RAG Knowledge.

    Note:
    - This service strictly manages Qdrant vector database ingestion and semantic search.
    - Each normalized knowledge item is treated as one complete atomic retrieval chunk.
    - The `condition` field represents topical/taxonomical association, NOT a user diagnosis.
    """

    def __init__(self, vector_store: BaseVectorStore, embedding_provider: BaseEmbeddingProvider):
        self.vector_store = vector_store
        self.embedding_provider = embedding_provider

    async def ingest_items(
        self,
        items: List[MentalHealthKnowledgeItem],
        collection_name: str = "knowledge",
    ) -> int:
        """
        Ensures Qdrant collection (vector_size=384) exists and upserts atomic knowledge items.
        """
        if not items:
            return 0

        # 1. Ensure collection exists with 384-dim cosine vectors
        await self.vector_store.create_collection(collection_name=collection_name, vector_size=384)

        # 2. Extract contents and generate 384-dim embeddings
        contents = [item.content for item in items]
        vectors = await self.embedding_provider.embed_documents(contents)

        # 3. Create VectorDocuments with complete traceability metadata
        documents: List[VectorDocument] = []
        for item, vector in zip(items, vectors):
            payload: Dict[str, Any] = {
                "id": item.id,
                "condition": item.condition,
                "knowledge_type": item.knowledge_type,
                "title": item.title,
                "content": item.content,
                "evidence_level": item.evidence_level,
                "source": item.source,
                "source_reference": item.source_reference,
                "limitations": item.limitations,
            }
            documents.append(
                VectorDocument(
                    id=item.id,
                    vector=vector,
                    payload=payload,
                )
            )

        # 4. Upsert into Qdrant Vector DB
        await self.vector_store.upsert(collection_name=collection_name, documents=documents)
        logger.info(f"Successfully ingested {len(documents)} atomic knowledge items into Qdrant collection '{collection_name}'.")
        return len(documents)

    async def search_knowledge(
        self,
        query: str,
        collection_name: str = "knowledge",
        limit: int = 5,
        condition: Optional[str] = None,
    ) -> List[Dict[str, Any]]:
        """
        Performs 384-dim semantic similarity search on Qdrant knowledge collection.
        Optionally filters results by topical condition association.
        """
        query_vector = await self.embedding_provider.embed_query(query)
        hits = await self.vector_store.search(
            collection_name=collection_name,
            query_vector=query_vector,
            limit=limit * 2 if condition else limit,
        )

        results: List[Dict[str, Any]] = []
        for hit in hits:
            payload = hit.payload
            if condition and payload.get("condition") != condition:
                continue
            results.append(payload)
            if len(results) >= limit:
                break

        return results
