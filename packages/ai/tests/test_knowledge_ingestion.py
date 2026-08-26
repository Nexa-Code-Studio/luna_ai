import json
import os
from pathlib import Path
from typing import List
import pytest

from ai.interfaces.embedding import BaseEmbeddingProvider
from ai.interfaces.vector_store import BaseVectorStore, VectorDocument
from ai.services.embedding_service import DefaultEmbeddingProvider
from ai.services.knowledge_ingestion_service import KnowledgeIngestionService
from shared.domain_types import MentalHealthKnowledgeItem

SEED_JSON_PATH = str(Path(__file__).resolve().parent.parent / "seeders" / "mental_health_knowledge.json")


class InMemoryVectorStore(BaseVectorStore):
    """Simple in-memory vector store for offline testing of Qdrant vector store contracts."""

    def __init__(self):
        self.collections = {}

    async def create_collection(self, collection_name: str, vector_size: int) -> bool:
        if collection_name not in self.collections:
            self.collections[collection_name] = {"vector_size": vector_size, "documents": {}}
        return True

    async def upsert(self, collection_name: str, documents: List[VectorDocument]) -> bool:
        if collection_name not in self.collections:
            await self.create_collection(collection_name, 384)
        for doc in documents:
            self.collections[collection_name]["documents"][doc.id] = doc
        return True

    async def search(
        self,
        collection_name: str,
        query_vector: List[float],
        limit: int = 5,
    ) -> List[VectorDocument]:
        if collection_name not in self.collections:
            return []

        docs = list(self.collections[collection_name]["documents"].values())
        
        # Simple dot product cosine similarity approximation for 384-dim normalized vectors
        def similarity(doc: VectorDocument) -> float:
            if not doc.vector or len(doc.vector) != len(query_vector):
                return 0.0
            return sum(a * b for a, b in zip(doc.vector, query_vector))

        docs_sorted = sorted(docs, key=similarity, reverse=True)
        return docs_sorted[:limit]


@pytest.mark.asyncio
async def test_knowledge_ingestion_and_traceability():
    """
    Tests knowledge ingestion of 10 atomic items into vector store and asserts
    that source traceability metadata remains 100% intact.
    """
    assert os.path.exists(SEED_JSON_PATH), f"Seed dataset not found at {SEED_JSON_PATH}"

    with open(SEED_JSON_PATH, "r", encoding="utf-8") as f:
        raw_items = json.load(f)

    items = [MentalHealthKnowledgeItem(**item) for item in raw_items]
    assert len(items) == 10, f"Expected exactly 10 atomic items, found {len(items)}"

    vector_store = InMemoryVectorStore()
    embedding_provider = DefaultEmbeddingProvider()
    service = KnowledgeIngestionService(vector_store, embedding_provider)

    count = await service.ingest_items(items, collection_name="knowledge")
    assert count == 10

    # 1. Traceability metadata assertion
    all_hits = await service.search_knowledge(query="stres dan emosi", limit=10)
    assert len(all_hits) == 10

    for hit in all_hits:
        assert "id" in hit and hit["id"].startswith("K")
        assert "source" in hit and len(hit["source"]) > 0
        assert "source_reference" in hit and len(hit["source_reference"]) > 0
        assert "evidence_level" in hit and hit["evidence_level"] in ["strong", "moderate", "low"]
        assert "limitations" in hit and len(hit["limitations"]) > 0
        assert "condition" in hit and hit["condition"] in ["stress", "anxiety", "depression", "emotional_regulation", "general"]
        assert "knowledge_type" in hit and hit["knowledge_type"] in ["psychoeducation", "self_help", "treatment"]

    # 2. Semantic search relevance check
    grounding_hits = await service.search_knowledge(query="badai emosional grounding indra", limit=2)
    assert len(grounding_hits) > 0
    top_hit_ids = [h["id"] for h in grounding_hits]
    assert "K002" in top_hit_ids or "K001" in top_hit_ids


@pytest.mark.asyncio
async def test_strict_exclusions():
    """
    Verifies that C-SSRS screener questions, DASS-21 items, and Crisis SOPs
    are STRICTLY EXCLUDED from the RAG knowledge seed dataset and vector store.
    """
    with open(SEED_JSON_PATH, "r", encoding="utf-8") as f:
        raw_items = json.load(f)

    ingested_ids = [item["id"] for item in raw_items]
    ingested_titles = [item["title"].lower() for item in raw_items]

    # Excluded item IDs
    excluded_ids = ["K006", "K007", "K012", "K014", "K015", "K016"]
    for ex_id in excluded_ids:
        assert ex_id not in ingested_ids, f"Excluded item '{ex_id}' must NOT be present in RAG seed dataset!"

    # Excluded content keywords
    for title in ingested_titles:
        assert "c-ssrs" not in title, "C-SSRS screener questions must NOT be in RAG knowledge!"
        assert "butir pertanyaan dass-21" not in title, "DASS-21 instrument items must NOT be in RAG knowledge!"
        assert "eskalasi krisis bunuh diri" not in title, "Crisis escalation SOP must NOT be in RAG knowledge!"
