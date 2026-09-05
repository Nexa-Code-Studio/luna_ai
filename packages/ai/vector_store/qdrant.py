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
        import uuid
        points = []
        for idx, doc in enumerate(documents, 1):
            point_id = doc.id
            if isinstance(point_id, str) and not point_id.isdigit():
                try:
                    uuid.UUID(point_id)
                except ValueError:
                    point_id = str(uuid.uuid5(uuid.NAMESPACE_DNS, point_id))
            elif isinstance(point_id, str) and point_id.isdigit():
                point_id = int(point_id)

            points.append(
                PointStruct(
                    id=point_id,
                    vector=doc.vector,
                    payload=doc.payload,
                )
            )
        await self.client.upsert(collection_name=collection_name, points=points)
        return True

    async def search(
        self,
        collection_name: str,
        query_vector: list[float],
        limit: int = 5,
    ) -> list[VectorDocument]:
        try:
            if hasattr(self.client, "query_points"):
                res = await self.client.query_points(
                    collection_name=collection_name,
                    query=query_vector,
                    limit=limit,
                )
                hits = res.points
            else:
                hits = await self.client.search(
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
                for hit in hits
            ]
        except Exception:
            import httpx
            async with httpx.AsyncClient() as http_client:
                search_url = f"{self.url.rstrip('/')}/collections/{collection_name}/points/search"
                resp = await http_client.post(search_url, json={"vector": query_vector, "limit": limit, "with_payload": True})
                resp.raise_for_status()
                data = resp.json().get("result", [])
                return [
                    VectorDocument(
                        id=str(item.get("id")),
                        vector=[],
                        payload=item.get("payload") or {},
                    )
                    for item in data
                ]
