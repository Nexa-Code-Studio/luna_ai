import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db_session
from app.models.user import User
from app.services.analytics_service import AnalyticsService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


async def _get_default_user(db: AsyncSession) -> User:
    query = select(User).where(User.email == "user.luna@gmail.com")
    res = await db.execute(query)
    user = res.scalar_one_or_none()
    if not user:
        query_any = select(User)
        res_any = await db.execute(query_any)
        user = res_any.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="Default user not found")
    return user


@router.get("/monitoring")
async def get_monitoring_data(
    period: str = Query("today", description="Period: today | week | month"),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Fetch emotional rhythm, mental health risks, and AI summary for the requested period."""
    user = await _get_default_user(db)
    return await AnalyticsService.get_monitoring_data(user.id, period, db)
