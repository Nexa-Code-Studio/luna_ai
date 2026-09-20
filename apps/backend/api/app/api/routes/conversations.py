import uuid
from datetime import UTC, datetime, date, time, timezone

import logging
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import decode_access_token
from app.core.tz import get_wib_day_range_utc, get_wib_today, to_wib
from app.db.session import get_db_session
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.enums import ConversationStatus, MessageType
from app.models.safety import EmotionAnalysis
from app.models.user import User
from app.services.ml_emotion_detector import MLEmotionDetectorService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/conversations", tags=["Conversations"])


class SendMessageRequest(BaseModel):
    content: str
    modality: str = "text"


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


def _analyze_message_emotion_fallback(text: str) -> tuple[str, str]:
    """Determine emotion tag and emoji dynamically from message text keywords."""
    t_low = (text or "").lower()
    anx_words = ["cemas", "takut", "nervous", "panggung", "khawatir", "panik", "deg-degan", "gugup", "takutnya", "bingung", "was-was", "tegang"]
    dep_words = ["sedih", "nangis", "menangis", "hampa", "sendiri", "kehilangan", "terpuruk", "putus asa", "kecewa", "patah hati", "bunuh diri"]
    str_words = ["stres", "capek", "lelah", "beban", "berat", "penat", "pusing", "mumet", "tekanan", "tugas", "deadline", "kerjaan", "letih"]
    ang_words = ["marah", "kesal", "jengkel", "benci", "emosi", "sebal", "kesel", "geram", "murka"]
    pos_words = ["lega", "senang", "bahagia", "terima kasih", "makasih", "enakan", "tenang", "nyaman", "santai", "alhamdulillah", "syukurlah", "baik", "bersyukur"]

    if any(w in t_low for w in anx_words):
        return "fear (78%)", "😨"
    if any(w in t_low for w in dep_words):
        return "sadness (82%)", "😔"
    if any(w in t_low for w in str_words):
        return "stress (75%)", "💥"
    if any(w in t_low for w in ang_words):
        return "anger (70%)", "😡"
    if any(w in t_low for w in pos_words):
        return "calm (85%)", "😌"

    return "netral (60%)", "😐"


def _get_message_emotion(
    m: Message, emotion_map: dict[uuid.UUID, EmotionAnalysis] | None = None
) -> tuple[str, str]:
    if m.role not in ("user",):
        return "", ""

    if emotion_map and m.id in emotion_map:
        emo = emotion_map[m.id]
        if emo and emo.primary_emotion:
            pct = int((float(emo.confidence) if emo.confidence else 0.8) * 100)
            emo_lower = emo.primary_emotion.lower()
            name_map = {
                "fearful": "fear",
                "sad": "sadness",
                "angry": "anger",
                "neutral": "netral",
                "happy": "joy",
            }
            display_name = name_map.get(emo_lower, emo_lower)
            emoji_map = {
                "happy": "😃", "joy": "😃", "senang": "😃", "bahagia": "😃",
                "calm": "😌", "tenang": "😌", "lega": "😌",
                "fearful": "😨", "fear": "😨", "cemas": "😨", "takut": "😨",
                "sad": "😔", "sadness": "😔", "sedih": "😔",
                "angry": "😡", "anger": "😡", "marah": "😡",
                "stress": "💥", "stres": "💥",
                "neutral": "😐", "netral": "😐",
            }
            return f"{display_name} ({pct}%)", emoji_map.get(emo_lower, "🌱")

    return _analyze_message_emotion_fallback(m.content)


def _format_conversation(
    c: Conversation, emotion_map: dict[uuid.UUID, EmotionAnalysis] | None = None
) -> dict[str, Any]:
    msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
    last_msg = msgs[-1].content if msgs else ""
    formatted_msgs = []
    for m in msgs:
        emo_tag, emo_emoji = _get_message_emotion(m, emotion_map)
        formatted_msgs.append({
            "id": str(m.id),
            "sender": "luna" if m.role in ("assistant", "luna") else "user",
            "text": m.content,
            "time": _format_time_local(m.created_at),
            "isAudio": m.message_type in (MessageType.VOICE, "voice", "audio"),
            "emotionTag": emo_tag,
            "emotionEmoji": emo_emoji,
        })

    return {
        "id": str(c.id),
        "title": c.title or "Sesi Percakapan",
        "is_title_generating": "$skeleton" in (c.title or ""),
        "lastMessage": last_msg,
        "lastMessageTime": _format_time_local(c.started_at),
        "messages": formatted_msgs,
    }


@router.get("")
async def get_conversations(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(Conversation.user_id == user.id)
        .order_by(Conversation.started_at.desc())
    )
    res = await db.execute(query)
    convs = res.scalars().all()

    message_ids = [m.id for c in convs for m in c.messages]
    emotion_map: dict[uuid.UUID, EmotionAnalysis] = {}
    if message_ids:
        emo_query = select(EmotionAnalysis).where(EmotionAnalysis.message_id.in_(message_ids))
        emo_res = await db.execute(emo_query)
        for emo in emo_res.scalars().all():
            emotion_map[emo.message_id] = emo

    return [_format_conversation(c, emotion_map) for c in convs]


@router.get("/today")
async def get_today_conversations(
    page: int = Query(1, ge=1, description="Page number for pagination"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve today's voice call sessions with local time formatting and backend pagination."""
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

    # Query emotion analysis for all messages in convs
    message_ids = [m.id for c in convs for m in c.messages]
    emotion_map: dict[uuid.UUID, EmotionAnalysis] = {}
    if message_ids:
        emo_query = select(EmotionAnalysis).where(EmotionAnalysis.message_id.in_(message_ids))
        emo_res = await db.execute(emo_query)
        for emo in emo_res.scalars().all():
            emotion_map[emo.message_id] = emo

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

        transcript_items = []
        for m in msgs:
            emo_tag, emo_emoji = _get_message_emotion(m, emotion_map)
            transcript_items.append({
                "role": m.role,
                "content": m.content,
                "time": _format_time_local(m.created_at),
                "emotionTag": emo_tag if m.role == "user" else None,
                "emotionEmoji": emo_emoji if m.role == "user" else None,
            })

        items.append({
            "id": str(c.id),
            "title": c.title or "Sesi Panggilan Suara LUNA",
            "is_title_generating": "$skeleton" in (c.title or ""),
            "date": f"Hari ini, {time_formatted}",
            "duration": _format_duration_str(c.started_at, c.last_message_at),
            "moodTag": mood_tag,
            "emotion_analysis": analysis,
            "transcript": transcript_items,
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
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve all messages from today's conversations ordered chronologically (Oldest First) with pagination."""
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

    # Query emotion analysis for all messages in convs
    message_ids = [m.id for c in convs for m in c.messages]
    emotion_map: dict[uuid.UUID, EmotionAnalysis] = {}
    if message_ids:
        emo_query = select(EmotionAnalysis).where(EmotionAnalysis.message_id.in_(message_ids))
        emo_res = await db.execute(emo_query)
        for emo in emo_res.scalars().all():
            emotion_map[emo.message_id] = emo

    all_msgs = []
    for c in convs:
        sorted_msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
        sess_title = (c.title or "Sesi Panggilan Suara LUNA").replace("$skeleton", "").strip()
        for m in sorted_msgs:
            if m.role in ("user", "assistant") and m.content and m.content.strip():
                is_user = m.role == "user"
                emo_tag, emo_emoji = _get_message_emotion(m, emotion_map)
                all_msgs.append({
                    "id": str(m.id),
                    "role": m.role,
                    "isUser": is_user,
                    "content": m.content,
                    "text": m.content,
                    "time": _format_time_local(m.created_at or c.started_at),
                    "sessionTitle": sess_title,
                    "emotionTag": emo_tag if is_user else None,
                    "emotionEmoji": emo_emoji if is_user else None,
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

    message_ids = [m.id for m in conv.messages] if conv.messages else []
    emotion_map: dict[uuid.UUID, EmotionAnalysis] = {}
    if message_ids:
        emo_query = select(EmotionAnalysis).where(EmotionAnalysis.message_id.in_(message_ids))
        emo_res = await db.execute(emo_query)
        for emo in emo_res.scalars().all():
            emotion_map[emo.message_id] = emo

    return _format_conversation(conv, emotion_map)


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

    if payload.content and payload.content.strip():
        try:
            analysis_result = await MLEmotionDetectorService.predict_message_emotion(payload.content)
            await MLEmotionDetectorService.save_emotion_to_db(user_msg.id, analysis_result, db)
            logger.info(f"🧠 [CHAT EMOTION PERSISTED]: Saved emotion for message {user_msg.id}")
        except Exception as emo_err:
            logger.warning(f"⚠️ [CHAT EMOTION EXCEPTION]: Failed to save emotion analysis: {emo_err}")

    return {
        "id": str(user_msg.id),
        "sender": "user",
        "text": user_msg.content,
        "time": "Sekarang",
        "isAudio": False,
    }
