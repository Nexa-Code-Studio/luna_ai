import uuid
from datetime import UTC, datetime, date, time, timezone

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.tz import get_wib_day_range_utc, get_wib_today, to_wib
from app.db.session import get_db_session
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.enums import ConversationStatus, MessageType
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/conversations", tags=["Conversations"])


class SendMessageRequest(BaseModel):
    content: str
    modality: str = "text"


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


def _format_time_local(dt: datetime | None) -> str:
    if not dt:
        return "09:15 AM"
    try:
        dt_wib = to_wib(dt)
        return dt_wib.strftime("%I:%M %p") if dt_wib else "09:15 AM"
    except Exception:
        return dt.strftime("%I:%M %p")


def _format_duration_str(started_at: datetime | None, last_message_at: datetime | None) -> str:
    if not started_at:
        return "00:00"
    end_time = last_message_at or datetime.now(timezone.utc)
    diff = int((end_time - started_at).total_seconds())
    if diff < 0:
        diff = 0
    mins = diff // 60
    secs = diff % 60
    return f"{mins:02d}:{secs:02d}"


def _format_conversation(c: Conversation) -> dict[str, Any]:
    msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
    last_msg = msgs[-1].content if msgs else ""
    return {
        "id": str(c.id),
        "title": c.title or "Sesi Percakapan",
        "is_title_generating": "$skeleton" in (c.title or ""),
        "lastMessage": last_msg,
        "lastMessageTime": _format_time_local(c.started_at),
        "messages": [
            {
                "id": str(m.id),
                "sender": "luna" if m.role in ("assistant", "luna") else "user",
                "text": m.content,
                "time": _format_time_local(m.created_at),
                "isAudio": m.message_type in (MessageType.VOICE, "voice", "audio"),
            }
            for m in msgs
        ],
    }


@router.get("")
async def get_conversations(db: AsyncSession = Depends(get_db_session)) -> list[dict[str, Any]]:
    user = await _get_default_user(db)
    query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.user_id == user.id)
        .order_by(Conversation.started_at.desc())
    )
    res = await db.execute(query)
    convs = res.scalars().all()

    return [_format_conversation(c) for c in convs]


@router.get("/today")
async def get_today_conversations(
    page: int = Query(1, ge=1, description="Page number for pagination"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve today's voice call sessions with local time formatting and backend pagination."""
    user = await _get_default_user(db)
    today_wib = get_wib_today()
    start_utc, end_utc = get_wib_day_range_utc(today_wib)

    # Count total today conversations
    count_query = (
        select(func.count())
        .select_from(Conversation)
        .where(
            Conversation.user_id == user.id,
            Conversation.started_at >= start_utc,
            Conversation.started_at <= end_utc,
        )
    )
    total_res = await db.execute(count_query)
    total_items = total_res.scalar() or 0

    offset = (page - 1) * limit
    query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(
            Conversation.user_id == user.id,
            Conversation.started_at >= start_utc,
            Conversation.started_at <= end_utc,
        )
        .order_by(Conversation.started_at.desc())
        .offset(offset)
        .limit(limit)
    )
    res = await db.execute(query)
    convs = res.scalars().all()

    # Query today's diary entry for cached emotion summary
    diary_query = select(DiaryEntry).where(DiaryEntry.user_id == user.id, DiaryEntry.entry_date == today_wib)
    res_diary = await db.execute(diary_query)
    today_diary = res_diary.scalar_one_or_none()

    mood_tag = today_diary.mood_tag if today_diary and today_diary.mood_tag else "Tenang & Nyaman 🌿"
    ai_insight = today_diary.ai_insight if today_diary and today_diary.ai_insight else "Pengguna merasa didengarkan dan tenang setelah berdialog bersama LUNA."

    items = []
    for c in convs:
        msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
        if not msgs:
            continue

        time_formatted = _format_time_local(c.started_at)

        analysis = {
            "dominant_emotion": mood_tag,
            "calm_score": "85%",
            "stress_level": "Rendah",
            "empathy_level": "Sangat Tinggi",
            "ai_insight": ai_insight,
            "emotions_breakdown": [
                {"label": "Ketenangan & Kedamaian", "emoji": "😌", "percent": 0.85, "color": "#4ECDC4"},
                {"label": "Bahagia & Puas", "emoji": "😃", "percent": 0.60, "color": "#FFE6A7"},
                {"label": "Tingkat Stres", "emoji": "😟", "percent": 0.15, "color": "#FF8B94"},
            ],
        }

        items.append({
            "id": str(c.id),
            "title": c.title or "Sesi Panggilan Suara LUNA",
            "is_title_generating": "$skeleton" in (c.title or ""),
            "date": f"Hari ini, {time_formatted}",
            "duration": _format_duration_str(c.started_at, c.last_message_at),
            "moodTag": mood_tag,
            "emotion_analysis": analysis,
            "transcript": [
                {
                    "role": m.role,
                    "content": m.content,
                    "time": _format_time_local(m.created_at),
                    "emotionTag": "fear (68%)" if m.role == "user" and "cemas" in m.content.lower() else None,
                    "emotionEmoji": "😟" if m.role == "user" and "cemas" in m.content.lower() else None,
                }
                for m in msgs
            ],
        })

    return {
        "items": items,
        "total": total_items,
        "page": page,
        "limit": limit,
        "has_more": (offset + len(items)) < total_items,
    }


@router.get("/today/messages")
async def get_today_conversation_messages(
    page: int = Query(1, ge=1, description="Page number for pagination"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve all messages from today's conversations ordered chronologically (Oldest First) with pagination."""
    user = await _get_default_user(db)
    today_wib = get_wib_today()
    start_utc, end_utc = get_wib_day_range_utc(today_wib)

    # Query all today's conversations ordered chronologically (Oldest First)
    conv_query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(
            Conversation.user_id == user.id,
            Conversation.started_at >= start_utc,
            Conversation.started_at <= end_utc,
        )
        .order_by(Conversation.started_at.asc())
    )
    conv_res = await db.execute(conv_query)
    convs = conv_res.scalars().all()

    all_msgs = []
    for c in convs:
        sorted_msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
        sess_title = (c.title or "Sesi Panggilan Suara LUNA").replace("$skeleton", "").strip()
        for m in sorted_msgs:
            if m.role in ("user", "assistant") and m.content and m.content.strip():
                is_user = m.role == "user"
                all_msgs.append({
                    "id": str(m.id),
                    "role": m.role,
                    "isUser": is_user,
                    "content": m.content,
                    "text": m.content,
                    "time": _format_time_local(m.created_at or c.started_at),
                    "sessionTitle": sess_title,
                    "emotionTag": "fear (68%)" if is_user and "cemas" in m.content.lower() else None,
                    "emotionEmoji": "😟" if is_user and "cemas" in m.content.lower() else None,
                })

    total_items = len(all_msgs)
    total_pages = (total_items + limit - 1) // limit if total_items > 0 else 1
    offset = (page - 1) * limit
    items = all_msgs[offset : offset + limit]

    return {
        "items": items,
        "total_items": total_items,
        "page": page,
        "limit": limit,
        "total_pages": total_pages,
    }


@router.get("/{conversation_id}")
async def get_conversation_by_id(conversation_id: str, db: AsyncSession = Depends(get_db_session)) -> dict[str, Any]:
    try:
        c_uuid = uuid.UUID(conversation_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid conversation ID")

    query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.id == c_uuid)
    )
    res = await db.execute(query)
    conv = res.scalar_one_or_none()

    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    return _format_conversation(conv)


@router.post("/{conversation_id}/messages")
async def send_message(
    conversation_id: str, payload: SendMessageRequest, db: AsyncSession = Depends(get_db_session)
) -> dict[str, Any]:
    try:
        c_uuid = uuid.UUID(conversation_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid conversation ID")

    query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.id == c_uuid)
    )
    res = await db.execute(query)
    conv = res.scalar_one_or_none()

    if not conv:
        raise HTTPException(status_code=404, detail="Conversation not found")

    next_seq = len(conv.messages) + 1
    user_msg = Message(
        conversation_id=conv.id,
        role="user",
        content=payload.content,
        message_type=MessageType.TEXT,
        sequence_number=next_seq,
    )
    db.add(user_msg)
    await db.commit()
    await db.refresh(user_msg)

    return {
        "id": str(user_msg.id),
        "sender": "user",
        "text": user_msg.content,
        "time": "Sekarang",
        "isAudio": False,
    }
