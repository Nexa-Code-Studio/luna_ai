import json
import math
import uuid
from collections import Counter
from datetime import UTC, datetime, date, time, timezone

import logging
from typing import Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.security import decode_access_token
from app.core.tz import get_wib_day_range_utc, get_wib_today, to_wib
from app.db.session import AsyncSessionLocal, get_db_session
from app.models.conversation import Conversation, Message, ConversationSummary
from app.models.diary import DiaryEntry
from app.models.enums import ConversationStatus, MessageType
from app.models.safety import EmotionAnalysis
from app.models.user import User
from app.services.ml_emotion_detector import MLEmotionDetectorService
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.interfaces.llm import LLMMessage

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/conversations", tags=["Conversations"])


class SendMessageRequest(BaseModel):
    content: str
    modality: str = "text"


async def _get_current_user(
    authorization: str | None = Header(None),
    token_query: str | None = Query(None, alias="token"),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    token = None
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1].strip()
    elif token_query:
        token = token_query.strip()

    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization Bearer atau token query diperlukan",
        )
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
    if not started_at or not last_message_at:
        return "00:00"
    try:
        t1 = started_at if started_at.tzinfo else started_at.replace(tzinfo=timezone.utc)
        t2 = last_message_at if last_message_at.tzinfo else last_message_at.replace(tzinfo=timezone.utc)
        diff = int((t2 - t1).total_seconds())
        if diff < 0:
            diff = 0
        mins = diff // 60
        secs = diff % 60
        return f"{mins:02d}:{secs:02d}"
    except Exception:
        return "00:00"


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
    user_emotions: list[tuple[str, str]] = []
    for m in msgs:
        emo_tag, emo_emoji = _get_message_emotion(m, emotion_map)
        if m.role in ("user",) and emo_tag:
            user_emotions.append((emo_tag, emo_emoji))
        formatted_msgs.append({
            "id": str(m.id),
            "sender": "luna" if m.role in ("assistant", "luna") else "user",
            "text": m.content,
            "time": _format_time_local(m.created_at),
            "isAudio": m.message_type in (MessageType.VOICE, "voice", "audio"),
            "emotionTag": emo_tag,
            "emotionEmoji": emo_emoji,
        })

    dominant_label = "Tenang & Nyaman"
    dominant_emoji = "😌"
    if user_emotions:
        counts: Counter[str] = Counter()
        emoji_by_name: dict[str, str] = {}
        for tag, emoji in user_emotions:
            name = tag.split()[0].lower() if tag else "netral"
            counts[name] += 1
            if emoji:
                emoji_by_name[name] = emoji

        most_common_name, _ = counts.most_common(1)[0]
        name_map = {
            "happy": "Lega & Senang",
            "joy": "Lega & Senang",
            "calm": "Tenang & Damai",
            "fear": "Cemas & Takut",
            "fearful": "Cemas & Takut",
            "anxiety": "Cemas & Gelisah",
            "sadness": "Sedih & Hampa",
            "sad": "Sedih & Hampa",
            "depression": "Sedih & Tertekan",
            "stress": "Stres & Lelah",
            "anger": "Marah & Kesal",
            "angry": "Marah & Kesal",
            "neutral": "Netral & Rileks",
            "netral": "Netral & Rileks",
        }
        dominant_label = name_map.get(most_common_name, most_common_name.capitalize())
        dominant_emoji = emoji_by_name.get(most_common_name, "😌")

    # Safety/Crisis Override: Jangan pernah kategorikan krisis atau niat menyakiti diri sebagai Netral & Rileks
    CRISIS_KEYWORDS = (
        "bunuh diri", "capek hidup", "mati saja", "ingin mati", "putus asa",
        "menyakiti diri", "gantung diri", "akhiri hidup", "tak sanggup lagi",
        "tidak sanggup hidup"
    )
    all_user_text = " ".join([m.content.lower() for m in msgs if m.role == "user" and m.content])
    if any(kw in all_user_text for kw in CRISIS_KEYWORDS):
        dominant_label = "Krisis / Sangat Tertekan"
        dominant_emoji = "🆘"

    end_time = c.last_message_at or (msgs[-1].created_at if msgs else c.started_at)
    duration_str = _format_duration_str(c.started_at, end_time)

    # Return summary from DB if exists; otherwise None to trigger client-side skeleton & stream
    summary_text = None
    if hasattr(c, "summaries") and c.summaries:
        summary_text = c.summaries[-1].summary

    return {
        "id": str(c.id),
        "title": c.title or "Sesi Percakapan",
        "is_title_generating": "$skeleton" in (c.title or ""),
        "lastMessage": last_msg,
        "lastMessageTime": _format_time_local(c.started_at),
        "duration": duration_str,
        "dominant_emotion": dominant_label,
        "dominant_emoji": dominant_emoji,
        "summary": summary_text,
        "messages": formatted_msgs,
    }


@router.get("")
async def get_conversations(
    page: int = Query(1, ge=1, description="Page number for pagination"),
    limit: int = Query(10, ge=1, le=100, description="Items per page"),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    count_query = (
        select(func.count())
        .select_from(Conversation)
        .where(Conversation.user_id == user.id)
    )
    total_res = await db.execute(count_query)
    total_items = total_res.scalar() or 0

    offset = (page - 1) * limit
    query = (
        select(Conversation)
        .options(
            selectinload(Conversation.messages),
            selectinload(Conversation.summaries),
        )
        .where(Conversation.user_id == user.id)
        .order_by(Conversation.started_at.desc())
        .offset(offset)
        .limit(limit)
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

    formatted_items = [_format_conversation(c, emotion_map) for c in convs]
    total_pages = max(1, math.ceil(total_items / limit)) if total_items > 0 else 1
    has_more = (offset + len(convs)) < total_items

    return {
        "items": formatted_items,
        "pagination": {
            "page": page,
            "limit": limit,
            "total_items": total_items,
            "total_pages": total_pages,
            "has_more": has_more,
        },
        "total": total_items,
        "page": page,
        "limit": limit,
        "has_more": has_more,
    }


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
        .options(
            selectinload(Conversation.messages),
            selectinload(Conversation.summaries),
        )
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


@router.get("/{conversation_id}/summary/stream")
async def stream_conversation_summary(
    conversation_id: uuid.UUID,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
):
    """Stream 2-3 sentence empathetic counseling summary token-by-token using SSE and persist upon completion."""
    query = (
        select(Conversation)
        .options(
            selectinload(Conversation.messages),
            selectinload(Conversation.summaries),
        )
        .where(Conversation.id == conversation_id, Conversation.user_id == user.id)
    )
    res = await db.execute(query)
    conv = res.scalar_one_or_none()
    if not conv:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Percakapan tidak ditemukan",
        )

    # 1. If already persisted in DB, yield cached summary immediately
    if conv.summaries and conv.summaries[-1].summary:
        existing_summary = conv.summaries[-1].summary

        async def cached_stream():
            yield f"data: {json.dumps({'token': existing_summary})}\n\n"
            yield f"data: {json.dumps({'done': True, 'summary': existing_summary})}\n\n"

        return StreamingResponse(
            cached_stream(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )

    # 2. Extract user and assistant messages for transcript
    msgs = sorted(conv.messages, key=lambda m: m.created_at) if conv.messages else []
    user_assistant_msgs = [
        m for m in msgs if m.role in ("user", "assistant") and m.content and m.content.strip()
    ]

    CRISIS_KEYWORDS = (
        "bunuh diri", "capek hidup", "mati saja", "ingin mati", "putus asa",
        "menyakiti diri", "gantung diri", "akhiri hidup", "tak sanggup lagi",
        "tidak sanggup hidup"
    )
    transcript_text = "\n".join([f"{m.role.upper()}: {m.content}" for m in user_assistant_msgs])
    full_lower = transcript_text.lower()
    has_crisis = any(kw in full_lower for kw in CRISIS_KEYWORDS)

    if not user_assistant_msgs:
        fallback_summary = "Sesi percakapan curhat bersama LUNA berjalan dengan tenang dan aman."

        async def empty_stream():
            yield f"data: {json.dumps({'token': fallback_summary})}\n\n"
            yield f"data: {json.dumps({'done': True, 'summary': fallback_summary})}\n\n"

        return StreamingResponse(
            empty_stream(),
            media_type="text/event-stream",
            headers={
                "Cache-Control": "no-cache",
                "Connection": "keep-alive",
                "X-Accel-Buffering": "no",
            },
        )

    system_prompt = LLMMessage(
        role="system",
        content=(
            "Anda adalah konselor psikologis profesional LUNA AI. "
            "Tugas Anda adalah membuat ringkasan percakapan konseling yang sangat ringkas, padat, dan menenangkan (tepat 2-3 kalimat Bahasa Indonesia).\n"
            "Pedoman wajib:\n"
            "1. Fokus pada esensi perasaan yang dicurahkan pengguna dan pendampingan reflektif dari LUNA.\n"
            "2. Gunakan nada bicara hangat, empatik, tenang, dan suportif.\n"
            "3. DILARANG KERAS mengutip mentah kata-kata pengguna dalam tanda kutip.\n"
            "4. Jika terdeteksi kondisi krisis berat, berikan narasi suportif yang menekankan ruang aman dan pentingnya pertolongan profesional.\n"
            "5. Hasilkan HANYA teks ringkasan langsung tanpa judul, tanpa pembuka/penutup, dan tanpa format markdown."
        ),
    )
    user_prompt = LLMMessage(
        role="user",
        content=f"Berikut transkrip percakapan suara:\n\n{transcript_text}\n\nBuat ringkasan konseling 2-3 kalimat:",
    )

    async def generate_stream():
        full_tokens: list[str] = []
        try:
            llm_provider = LLMFactory.get_provider()
            async for token in llm_provider.stream_response([system_prompt, user_prompt]):
                full_tokens.append(token)
                yield f"data: {json.dumps({'token': token})}\n\n"
        except Exception as e:
            logger.error(f"⚠️ [SUMMARY STREAM LLM EXCEPTION]: {e}")
            fallback_text = (
                "Pengguna meluangkan waktu untuk mengekspresikan beban emosional yang berat dalam sesi ini. "
                "LUNA hadir mendampingi secara suportif, memberikan ruang aman untuk bercerita, "
                "dan menegaskan bahwa setiap perasaan berharga serta bantuan selalu tersedia."
                if has_crisis
                else "Pengguna berbagi refleksi harian dan tantangan perasaan secara terbuka. "
                "LUNA memberikan tanggapan yang menenangkan serta ruang aman untuk meredakan ketegangan."
            )
            if not full_tokens:
                yield f"data: {json.dumps({'token': fallback_text})}\n\n"
                full_tokens.append(fallback_text)

        full_summary = "".join(full_tokens).strip()
        # Clean any stray wrapping quotes
        if full_summary.startswith('"') and full_summary.endswith('"') and len(full_summary) > 2:
            full_summary = full_summary[1:-1].strip()

        # Persist summary to database so subsequent calls are instantaneous
        if full_summary:
            try:
                async with AsyncSessionLocal() as db_stream:
                    new_summary = ConversationSummary(
                        conversation_id=conversation_id,
                        summary=full_summary,
                    )
                    db_stream.add(new_summary)
                    await db_stream.commit()
                    logger.info(f"✅ [SUMMARY STREAM PERSISTED]: Conversation {conversation_id}")
            except Exception as db_err:
                logger.error(f"⚠️ [FAILED TO PERSIST STREAM SUMMARY]: {db_err}")

        dominant_emotion = "Krisis / Sangat Tertekan" if has_crisis else None
        dominant_emoji = "🆘" if has_crisis else None

        yield f"data: {json.dumps({'done': True, 'summary': full_summary, 'dominant_emotion': dominant_emotion, 'dominant_emoji': dominant_emoji})}\n\n"

    return StreamingResponse(
        generate_stream(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )

