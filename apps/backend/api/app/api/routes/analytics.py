import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.db.session import get_db_session
from app.models.user import User
from app.services.analytics_service import AnalyticsService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


async def _get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization Bearer diperlukan",
        )

    token = authorization.split("Bearer ")[1].strip()
    decoded = decode_access_token(token)
    if not decoded or "sub" not in decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token akses tidak valid atau telah kedaluwarsa",
        )

    try:
        u_uuid = uuid.UUID(decoded["sub"])
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Format user ID dalam token tidak valid",
        )

    query_jwt = select(User).where(User.id == u_uuid)
    res_jwt = await db.execute(query_jwt)
    user = res_jwt.scalar_one_or_none()
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Pengguna tidak ditemukan atau telah dinonaktifkan",
        )

    return user


@router.get("/monitoring")
async def get_monitoring_data(
    period: str = Query("today", description="Period: today | week | month"),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Fetch emotional rhythm, mental health risks, and AI summary for the requested period."""
    return await AnalyticsService.get_monitoring_data(user.id, period, db)


