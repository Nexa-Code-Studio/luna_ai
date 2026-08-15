from collections.abc import AsyncGenerator

from redis.asyncio import Redis, from_url
from shared.config import settings


async def get_redis_client() -> AsyncGenerator[Redis, None]:
    """Dependency for providing Async Redis client."""
    client: Redis = from_url(settings.REDIS_URL, decode_responses=True)
    try:
        yield client
    finally:
        await client.close()
