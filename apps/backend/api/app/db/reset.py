import asyncio
import logging
import httpx

from app.db.session import engine
from app.models.base import BaseModel
from app.db.seed import seed_master_data
from shared.config import settings

logger = logging.getLogger(__name__)


async def reset_qdrant_vector_memory() -> None:
    if not settings.QDRANT_URL:
        return
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            res = await client.get(f"{settings.QDRANT_URL}/collections")
            if res.status_code == 200:
                collections = res.json().get("result", {}).get("collections", [])
                for col in collections:
                    name = col.get("name")
                    if name:
                        await client.delete(f"{settings.QDRANT_URL}/collections/{name}")
                        logger.info(f"🗑️ Deleted Qdrant vector collection: '{name}'")
    except Exception as e:
        logger.warning(f"⚠️ Could not reset Qdrant collections: {e}")


async def reset_and_seed_db() -> None:
    """Drops all existing database tables, clears Qdrant vector memory, recreates schema, and seeds fresh master data."""
    logger.info("🗑️ Dropping all existing database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(BaseModel.metadata.drop_all)
    logger.info("✅ All tables dropped successfully.")

    await reset_qdrant_vector_memory()

    logger.info("🏗️ Recreating database schema tables...")
    async with engine.begin() as conn:
        await conn.run_sync(BaseModel.metadata.create_all)
    logger.info("✅ Database schema recreated successfully.")

    logger.info("🌱 Seeding fresh initial master data...")
    user = await seed_master_data()
    logger.info(f"🎉 Database reset and re-seeded successfully for Master User: {user.email}")


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    logger.info("🚀 Starting database reset & re-seeding process...")
    asyncio.run(reset_and_seed_db())


if __name__ == "__main__":
    main()
