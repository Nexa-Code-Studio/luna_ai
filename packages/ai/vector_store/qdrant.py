from ai.interfaces.vector_store import BaseVectorStore, VectorDocument
from qdrant_client import AsyncQdrantClient
from qdrant_client.http.models import Distance, PointStruct, VectorParams


class QdrantVectorStore(BaseVectorStore):
    """Qdrant implementation of BaseVectorStore."""

    def __init__(self, url: str):
        self.url = url
        self.client = AsyncQdrantClient(url=self.url)

    async def create_collection(self, collection_name: str, vector_size: int) -> bool:
        exists = await self.client.collection_exists(collection_name=collection_name)
        if not exists:
            await self.client.create_collection(
                collection_name=collection_name,
                vectors_config=VectorParams(size=vector_size, distance=Distance.COSINE),
            )
        return True

    async def upsert(self, collection_name: str, documents: list[VectorDocument]) -> bool:
        points = [
            PointStruct(
                id=doc.id,
                vector=doc.vector,
                payload=doc.payload,
            )
            for doc in documents
        ]
        await self.client.upsert(collection_name=collection_name, points=points)
        return True

    async def search(
        self,
        collection_name: str,
        query_vector: list[float],
        limit: int = 5,
    ) -> list[VectorDocument]:
        search_result = await self.client.search(
            collection_name=collection_name,
            query_vector=query_vector,
            limit=limit,
        )
        return [
            VectorDocument(
                id=str(hit.id),
                vector=[],
                payload=hit.payload or {},
            )
            for hit in search_result
        ]
