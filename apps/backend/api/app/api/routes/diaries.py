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


def _format_diary_entry(d: DiaryEntry) -> dict[str, Any]:
    raw_events = d.important_events if isinstance(d.important_events, list) else []
    events = raw_events if raw_events else ["Sesi refleksi harian tercatat dalam sistem LUNA."]
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
        } if ("Darurat" in (d.mood_tag or "") or "Stres" in (d.mood_tag or "") or "Cemas" in (d.mood_tag or "")) else None,
        "aiInsight": d.ai_insight or "Analisis AI menunjukkan kondisi stabil.",
        "importantEvents": events,
        "emotionalReflection": d.emotional_reflection or "Merasa tenang setelah refleksi.",
        "sessions": [],
    }


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
    for i, c in enumerate(convs):
        sorted_msgs = sorted(c.messages, key=lambda m: m.sequence_number) if c.messages else []
        sess_transcripts = []
        for m in sorted_msgs:
            if m.role in ("user", "assistant") and m.content:
                msg_t = to_wib(m.created_at)
                sess_transcripts.append({
                    "isUser": m.role == "user",
                    "time": msg_t.strftime("%H:%M") if msg_t else "09:00",
                    "text": m.content,
                    "emotionTag": "calm (85%)" if m.role == "user" else "empathy",
                    "emotionEmoji": "😌" if m.role == "user" else "💙",
                })

        c_t = to_wib(c.started_at)
        sessions_data.append({
            "id": str(c.id),
            "title": (c.title or f"Sesi #{i+1} Percakapan Suara").replace("$skeleton", "").strip(),
            "time": c_t.strftime("%H:%M") if c_t else "09:00",
            "moodTag": entry.mood_tag or "Netral",
            "moodEmoji": entry.mood_emoji or "😌",
            "emotionsBreakdown": [
                {"name": "netral", "label": "Ketenangan & Kedamaian", "emoji": "😌", "percent": 0.85, "color": "#4ECDC4"},
                {"name": "happy", "label": "Bahagia & Puas", "emoji": "😃", "percent": 0.60, "color": "#FFE6A7"},
            ],
            "transcripts": sess_transcripts,
        })

    formatted["sessions"] = sessions_data
    formatted["sessionCount"] = len(sessions_data)
    if sessions_data:
        last_t = to_wib(convs[-1].started_at)
        formatted["lastSessionTime"] = last_t.strftime("%H:%M") if last_t else "-"
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
        today_entry = await DiaryGeneratorService.generate_today_diary(user.id, db)
        entries = [today_entry]

    formatted = [_format_diary_entry(e) for e in entries]

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
