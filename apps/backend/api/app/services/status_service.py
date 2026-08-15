import httpx
from redis.asyncio import Redis
from shared.config import settings
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


class SystemStatusService:
    """Reusable application service for checking infrastructure dependencies."""

    @staticmethod
    async def check_database(session: AsyncSession) -> str:
        try:
            await session.execute(text("SELECT 1"))
            return "healthy"
        except Exception as e:
            return f"unhealthy: {e!s}"

    @staticmethod
    async def check_redis(redis_client: Redis) -> str:
        try:
            pong = await redis_client.ping()
            return "healthy" if pong else "unhealthy"
        except Exception as e:
            return f"unhealthy: {e!s}"

    @staticmethod
    async def check_qdrant(qdrant_url: str = settings.QDRANT_URL) -> str:
        try:
            async with httpx.AsyncClient(timeout=2.0) as client:
                res = await client.get(f"{qdrant_url}/healthz")
                return "healthy" if res.status_code == 200 else f"status_{res.status_code}"
        except Exception as e:
            return f"unhealthy: {e!s}"
