import logging
import uuid
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import decode_access_token
from app.core.tz import get_wib_day_range_utc, get_wib_today
from ai.services.dass_extraction_service import DASSExtractionService
from app.db.session import get_db_session
from app.models.conversation import Conversation, Message
from app.models.user import User
from app.schemas.dass import DASSAssessmentResponse, DASSAssessmentUpdate
from app.services.dass_service import DASSService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/dass", tags=["DASS-21"])


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


@router.get("/today", response_model=DASSAssessmentResponse)
async def get_today_dass(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> Any:
    """Mengambil status dan butir asesmen DASS-21 hari ini untuk pengguna."""
    today_wib = get_wib_today()
    return await DASSService.get_today_assessment(user.id, today_wib, db)


@router.put("/today", response_model=DASSAssessmentResponse)
async def update_today_dass(
    payload: DASSAssessmentUpdate,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> Any:
    """Menerima koreksi skor butir DASS-21 dari pengguna dan melakukan rekalkulasi skor."""
    today_wib = get_wib_today()
    return await DASSService.update_user_assessment(user.id, today_wib, payload.items, db)


@router.put("/{assessment_id}", response_model=DASSAssessmentResponse)
async def update_dass_by_id(
    assessment_id: uuid.UUID,
    payload: DASSAssessmentUpdate,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> Any:
    """Menerima koreksi skor butir DASS-21 berdasarkan ID asesmen spesifik."""
    today_wib = get_wib_today()
    return await DASSService.update_user_assessment(user.id, today_wib, payload.items, db)


@router.post("/extract-today", response_model=DASSAssessmentResponse)
async def extract_today_dass(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> Any:
    """Memicu analisis ekstraksi AI 21 butir DASS-21 dari seluruh transkrip percakapan hari ini."""
    today_wib = get_wib_today()
    start_utc, end_utc = get_wib_day_range_utc(today_wib)

    # Ambil percakapan hari ini
    conv_stmt = (
        select(Conversation)
        .where(
            Conversation.user_id == user.id,
            Conversation.created_at >= start_utc,
            Conversation.created_at <= end_utc,
        )
        .options(selectinload(Conversation.messages))
    )
    conv_res = await db.execute(conv_stmt)
    conversations = conv_res.scalars().all()

    formatted_msgs = []
    latest_conv_id = None
    for c in conversations:
        latest_conv_id = c.id
        for m in sorted(c.messages, key=lambda x: x.created_at):
            if m.content and m.content.strip():
                formatted_msgs.append(f"{m.role.upper()}: {m.content}")

    transcript = "\n".join(formatted_msgs)
    extractor = DASSExtractionService()
    extracted_items = await extractor.extract_from_transcript(transcript)

    saved_record = await DASSService.save_or_update_extracted(
        user_id=user.id,
        assessed_date=today_wib,
        extracted_items=extracted_items,
        conversation_id=latest_conv_id,
        db=db,
    )
    return DASSAssessmentResponse.model_validate(saved_record)
