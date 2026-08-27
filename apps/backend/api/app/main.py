from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from shared.config import settings

from app.api.routes.analytics import router as analytics_router
from app.api.routes.auth import router as auth_router
from app.api.routes.call import router as call_router
from app.api.routes.conversations import router as conversations_router
from app.api.routes.diaries import router as diaries_router
from app.api.routes.health import router as health_router
from app.api.routes.recommendations import router as recommendations_router
from app.api.routes.user import router as user_router
from app.core.logging import setup_logging

logger = logging.getLogger(__name__)


@asynccontextmanager
async def lifespan(app: FastAPI):
    setup_logging()
    if settings.APP_ENV == "development":
        try:
            from app.db.seed import seed_master_data
            logger.info("APP_ENV=development: Running auto-seeder...")
            await seed_master_data()
        except Exception as e:
            logger.warning(f"Auto-seed during development startup skipped: {e}")
    yield


app = FastAPI(
    title="Luna AI Backend API",
    version="0.1.0",
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health_router, tags=["Health"])
app.include_router(auth_router, prefix="/api/v1")
app.include_router(user_router, prefix="/api/v1")
app.include_router(diaries_router, prefix="/api/v1")
app.include_router(analytics_router, prefix="/api/v1")
app.include_router(recommendations_router, prefix="/api/v1")
app.include_router(conversations_router, prefix="/api/v1")
app.include_router(call_router, prefix="/api/v1")


@app.get("/")
async def root():
    return {"message": "Luna AI API Server", "environment": settings.APP_ENV}
