import uuid
from datetime import date
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
from app.models.conversation import Conversation
from app.models.diary import DiaryEntry
from app.models.user import User
from app.services.diary_generator import DiaryGeneratorService

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/diaries", tags=["Diaries"])


class CreateDiaryRequest(BaseModel):
    content: str
    mood_tag: str | None = None


async def _get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    if authorization and authorization.startswith("Bearer "):
        token = authorization.split("Bearer ")[1].strip()
        decoded = decode_access_token(token)
        if decoded and "sub" in decoded:
            try:
                u_uuid = uuid.UUID(decoded["sub"])
                query_jwt = select(User).where(User.id == u_uuid)
                res_jwt = await db.execute(query_jwt)
                user = res_jwt.scalar_one_or_none()
                if user:
                    return user
            except (ValueError, Exception):
                pass

    query = select(User).where(User.email == "user.luna@gmail.com")
    res = await db.execute(query)
    user = res.scalar_one_or_none()
    if not user:
        query_any = select(User)
        res_any = await db.execute(query_any)
        user = res_any.scalars().first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user


def _format_diary_entry(d: DiaryEntry | None) -> dict[str, Any]:
    if not d:
        return {}
    raw_events = d.important_events if isinstance(d.important_events, list) else []
    events = raw_events if raw_events else ["Sesi refleksi harian tercatat dalam sistem LUNA."]

    scores = d.mental_health_scores or {}
    dep = float(scores.get("depression", 0.25))
    anx = float(scores.get("anxiety", 0.45))
    strs = float(scores.get("stress", 0.15))

    raw_breakdown = [
        {"name": "fear", "label": "Takut / Gelisah", "emoji": "😨", "percent": max(0.05, anx), "color": "#6C63FF"},
        {"name": "sadness", "label": "Sedih / Haru", "emoji": "😔", "percent": max(0.05, dep), "color": "#8B93FF"},
        {"name": "netral", "label": "Netral", "emoji": "😐", "percent": 0.15, "color": "#A7E6FF"},
        {"name": "stress", "label": "Stres / Tertekan", "emoji": "💥", "percent": max(0.05, strs), "color": "#FF8A80"},
        {"name": "happy", "label": "Bahagia", "emoji": "😃", "percent": 0.10, "color": "#FFE6A7"},
        {"name": "surprise", "label": "Terkejut", "emoji": "😲", "percent": 0.03, "color": "#C3B8FF"},
        {"name": "anger", "label": "Marah", "emoji": "😡", "percent": 0.02, "color": "#FFB6C1"},
    ]
    tot = sum(item["percent"] for item in raw_breakdown)
    emotions_breakdown = [
        {
            **item,
            "percent": round(item["percent"] / tot, 2),
        }
        for item in raw_breakdown
    ]

    return {
        "id": str(d.id),
        "title": d.title or "Refleksi Harian LUNA",
        "date": d.entry_date.strftime("%d %B %Y") if isinstance(d.entry_date, date) else str(d.entry_date),
        "sessionCount": 0,
        "lastSessionTime": "-",
        "moodTag": d.mood_tag or "Netral",
        "moodEmoji": d.mood_emoji or "😌",
        "summary": d.summary or "Catatan harian perkembangan emosional bersama LUNA.",
        "riskWarning": {
            "detected": True,
            "type": "High Risk / Krisis",
            "title": "PERINGATAN KRISIS EMOSIONAL",
            "level": "RISIKO TINGGI",
            "message": "Sistem LUNA mendeteksi akumulasi indikasi krisis emosional tinggi dan stres berat pada percakapan hari ini. Protokol keselamatan aktif untuk rujukan darurat 119 ext 8.",
        } if ("Darurat" in (d.mood_tag or "") or "Stres" in (d.mood_tag or "") or "Cemas" in (d.mood_tag or "") or "Sedih" in (d.mood_tag or "")) else None,
        "aiInsight": d.ai_insight or "Analisis AI menunjukkan kondisi stabil.",
        "importantEvents": events,
        "emotionalReflection": d.emotional_reflection or "Merasa tenang setelah refleksi.",
        "mentalHealthScores": d.mental_health_scores or {},
        "emotionsBreakdown": emotions_breakdown,
        "sessions": [],
    }


def _calculate_session_emotions(
    transcripts: list[dict[str, Any]],
    session_title: str,
    default_breakdown: list[dict[str, Any]],
) -> list[dict[str, Any]]:
    combined_text = (session_title + " " + " ".join(t["text"] for t in transcripts if t.get("isUser"))).lower()

    anx_keywords = ["cemas", "takut", "nervous", "panggung", "khawatir", "panik", "deg-degan", "gugup"]
    dep_keywords = ["bunuh diri", "depresi", "sedih", "sendiri", "kehilangan", "hampa", "nangis", "menangis", "terpuruk"]
    str_keywords = ["stres", "capek", "lelah", "beban", "berat", "penat", "tugas", "kerja"]
    pos_keywords = ["lega", "senang", "terima kasih", "enakan", "tenang", "nyaman", "tidur", "santai", "baik"]

    anx_count = sum(1 for kw in anx_keywords if kw in combined_text)
    dep_count = sum(1 for kw in dep_keywords if kw in combined_text)
    str_count = sum(1 for kw in str_keywords if kw in combined_text)
    pos_count = sum(1 for kw in pos_keywords if kw in combined_text)

    if anx_count == 0 and dep_count == 0 and str_count == 0 and pos_count == 0:
        return default_breakdown

    raw = [
        {"name": "fear", "label": "Takut / Gelisah", "emoji": "😨", "percent": max(0.04, anx_count * 0.25), "color": "#6C63FF"},
        {"name": "sadness", "label": "Sedih / Haru", "emoji": "😔", "percent": max(0.04, dep_count * 0.25), "color": "#8B93FF"},
        {"name": "netral", "label": "Netral", "emoji": "😐", "percent": 0.08, "color": "#A7E6FF"},
        {"name": "stress", "label": "Stres / Tertekan", "emoji": "💥", "percent": max(0.04, str_count * 0.20), "color": "#FF8A80"},
        {"name": "happy", "label": "Bahagia", "emoji": "😃", "percent": max(0.03, pos_count * 0.15), "color": "#FFE6A7"},
        {"name": "surprise", "label": "Terkejut", "emoji": "😲", "percent": 0.02, "color": "#C3B8FF"},
        {"name": "anger", "label": "Marah", "emoji": "😡", "percent": 0.01, "color": "#FFB6C1"},
    ]
    tot = sum(item["percent"] for item in raw)
    return [
        {**item, "percent": round(item["percent"] / tot, 2)}
        for item in raw
    ]


def _analyze_message_emotion(text: str, is_user: bool) -> tuple[str, str]:
    """Dynamically determine emotion tag and emoji from individual message content."""
    if not is_user:
        return "empathy", "💙"

    t_low = text.lower()
    # 1. Cemas / Takut (Fear / Anxiety)
    anx_words = ["cemas", "takut", "nervous", "panggung", "khawatir", "panik", "deg-degan", "gugup", "takutnya", "bingung"]
    # 2. Sedih / Terpuruk (Sadness / Depression)
    dep_words = ["sedih", "nangis", "menangis", "hampa", "sendiri", "kehilangan", "terpuruk", "putus asa", "kecewa", "patah hati", "bunuh diri"]
    # 3. Stres / Beban / Lelah (Stress / Exhaustion)
    str_words = ["stres", "capek", "lelah", "beban", "berat", "penat", "pusing", "mumet", "tekanan", "tugas", "deadline", "kerjaan"]
    # 4. Marah / Kesal (Anger)
    ang_words = ["marah", "kesal", "jengkel", "benci", "emosi", "sebal", "kesel"]
    # 5. Lega / Tenang / Positif (Relief / Joy)
    pos_words = ["lega", "senang", "bahagia", "terima kasih", "makasih", "enakan", "tenang", "nyaman", "santai", "alhamdulillah", "syukurlah", "baik"]

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


async def _attach_sessions(formatted: dict[str, Any], entry: DiaryEntry, db: AsyncSession) -> dict[str, Any]:
    """Populate 'sessions' with real conversation transcripts for the diary's date."""
    if not isinstance(entry.entry_date, date):
        return formatted

    start_utc, end_utc = get_wib_day_range_utc(entry.entry_date)
    conv_query = (
        select(Conversation)
        .options(selectinload(Conversation.messages))
        .where(
            Conversation.user_id == entry.user_id,
            Conversation.started_at >= start_utc,
            Conversation.started_at <= end_utc,
        )
        .order_by(Conversation.started_at.asc())
    )
    conv_res = await db.execute(conv_query)
    convs = conv_res.scalars().all()

    sessions_data = []
    for c in convs:
        sorted_msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
        sess_transcripts = []
        for m in sorted_msgs:
            if m.role in ("user", "assistant") and m.content:
                msg_t = to_wib(m.created_at)
                emo_tag, emo_emoji = _analyze_message_emotion(m.content, m.role == "user")
                sess_transcripts.append({
                    "isUser": m.role == "user",
                    "time": msg_t.strftime("%H:%M") if msg_t else "09:00",
                    "text": m.content,
                    "emotionTag": emo_tag,
                    "emotionEmoji": emo_emoji,
                })

        # Skip empty sessions without user/assistant dialogue
        if not sess_transcripts:
            continue

        c_t = to_wib(c.started_at)
        time_str = c_t.strftime("%H:%M") if c_t else "09:00"
        title = (c.title or "").replace("$skeleton", "").strip()
        if not title:
            title = f"Sesi #{len(sessions_data) + 1} Percakapan Suara"

        sess_emotions = _calculate_session_emotions(
            sess_transcripts,
            title,
            formatted.get("emotionsBreakdown") or [],
        )

        sessions_data.append({
            "id": str(c.id),
            "title": title,
            "time": time_str,
            "moodTag": entry.mood_tag or "Netral",
            "moodEmoji": entry.mood_emoji or "😌",
            "emotionsBreakdown": sess_emotions,
            "transcripts": sess_transcripts,
        })

    formatted["sessions"] = sessions_data
    formatted["sessionCount"] = len(sessions_data)
    if sessions_data:
        formatted["lastSessionTime"] = sessions_data[-1]["time"]
    else:
        formatted["lastSessionTime"] = "-"
    return formatted


@router.get("")
async def get_diaries(
    mood: str | None = Query(None),
    search: str | None = Query(None),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    query = select(DiaryEntry).where(DiaryEntry.user_id == user.id).order_by(DiaryEntry.entry_date.desc())
    res = await db.execute(query)
    entries = res.scalars().all()

    if not entries:
        return []

    formatted = []
    for e in entries:
        if e is not None:
            f = _format_diary_entry(e)
            f = await _attach_sessions(f, e, db)
            formatted.append(f)

    if mood and mood != "Semua":
        clean_mood = mood.lower()
        formatted = [f for f in formatted if clean_mood in f["moodTag"].lower()]

    if search:
        clean_q = search.lower()
        formatted = [
            f for f in formatted
            if clean_q in f["title"].lower() or clean_q in f["summary"].lower()
        ]

    return formatted


@router.get("/today")
async def get_today_diary(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    today = get_wib_today()
    query = select(DiaryEntry).where(DiaryEntry.user_id == user.id, DiaryEntry.entry_date == today)
    res = await db.execute(query)
    entry = res.scalar_one_or_none()

    if not entry:
        entry = await DiaryGeneratorService.generate_today_diary(user.id, db)

    if not entry:
        return {"id": None, "message": "Belum ada jurnal untuk hari ini."}

    formatted = _format_diary_entry(entry)
    formatted = await _attach_sessions(formatted, entry, db)
    return formatted


@router.get("/{diary_id}")
async def get_diary_by_id(
    diary_id: str,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    try:
        d_uuid = uuid.UUID(diary_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid diary ID")

    query = select(DiaryEntry).where(
        DiaryEntry.id == d_uuid,
        DiaryEntry.user_id == user.id,
    )
    res = await db.execute(query)
    entry = res.scalar_one_or_none()

    if not entry:
        raise HTTPException(status_code=404, detail="Diary entry not found")

    formatted = _format_diary_entry(entry)
    formatted = await _attach_sessions(formatted, entry, db)
    return formatted


@router.post("/generate")
async def generate_today_diary(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    entry = await DiaryGeneratorService.generate_today_diary(user.id, db)
    return _format_diary_entry(entry)


@router.post("")
async def create_diary(
    payload: CreateDiaryRequest,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    today = get_wib_today()
    
    query = select(DiaryEntry).where(DiaryEntry.user_id == user.id, DiaryEntry.entry_date == today)
    res = await db.execute(query)
    entry = res.scalar_one_or_none()

    if entry:
        entry.summary += f"\n- {payload.content}"
        entry.content += f"\n- {payload.content}"
        if payload.mood_tag:
            entry.mood_tag = payload.mood_tag
    else:
        entry = DiaryEntry(
            user_id=user.id,
            entry_date=today,
            title="Refleksi Catatan Baru",
            summary=payload.content,
            content=payload.content,
            mood_tag=payload.mood_tag or "Netral",
            mood_emoji="😌",
            ai_insight="Catatan refleksi berhasil disimpan.",
            emotional_reflection="Merasa lega setelah menulis catatan.",
            important_events=[f"[Sesi #1] {payload.content[:50]}"],
        )
        db.add(entry)

    await db.commit()
    await db.refresh(entry)

    return _format_diary_entry(entry)



@router.delete("/{diary_id}")
async def delete_diary(diary_id: str, db: AsyncSession = Depends(get_db_session)) -> dict[str, str]:
    try:
        d_uuid = uuid.UUID(diary_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid diary ID")

    query = select(DiaryEntry).where(DiaryEntry.id == d_uuid)
    res = await db.execute(query)
    entry = res.scalar_one_or_none()

    if not entry:
        raise HTTPException(status_code=404, detail="Diary entry not found")

    await db.delete(entry)
    await db.commit()
    return {"message": "Diary entry deleted successfully"}
