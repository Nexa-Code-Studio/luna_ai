import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db_session
from app.models.recommendation import RecommendationItem

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


@router.get("")
async def get_recommendations(db: AsyncSession = Depends(get_db_session)) -> list[dict[str, Any]]:
    query = select(RecommendationItem)
    res = await db.execute(query)
    items = res.scalars().all()

    return [
        {
            "id": str(r.id),
            "title": r.title,
            "category": r.category,
            "duration": r.duration,
            "level": r.level,
            "description": r.description,
            "isCompleted": r.is_completed,
        }
        for r in items
    ]


@router.post("/{recommendation_id}/complete")
async def mark_recommendation_completed(
    recommendation_id: str, db: AsyncSession = Depends(get_db_session)
) -> dict[str, str]:
    try:
        r_uuid = uuid.UUID(recommendation_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid recommendation ID")

    query = select(RecommendationItem).where(RecommendationItem.id == r_uuid)
    res = await db.execute(query)
    item = res.scalar_one_or_none()

    if not item:
        raise HTTPException(status_code=404, detail="Recommendation item not found")

    item.is_completed = True
    await db.commit()
    return {"message": "Recommendation marked as completed"}
