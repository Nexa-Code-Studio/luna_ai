from app.api.dependencies import get_redis_client
from app.schemas.health import HealthCheckResponse
from app.services.status_service import SystemStatusService
from fastapi import APIRouter, Depends
from redis.asyncio import Redis
from shared.config import settings
from shared.database import get_db_session
from sqlalchemy.ext.asyncio import AsyncSession

router = APIRouter()


@router.get("/health", response_model=HealthCheckResponse)
async def health_check(
    db: AsyncSession = Depends(get_db_session),
    redis: Redis = Depends(get_redis_client),
) -> HealthCheckResponse:
    """GET /health endpoint for application server and dependency health check."""
    db_status = await SystemStatusService.check_database(db)
    redis_status = await SystemStatusService.check_redis(redis)
    qdrant_status = await SystemStatusService.check_qdrant()

    return HealthCheckResponse(
        status="ok",
        app="api",
        environment=settings.APP_ENV,
        database=db_status,
        redis=redis_status,
        qdrant=qdrant_status,
    )
