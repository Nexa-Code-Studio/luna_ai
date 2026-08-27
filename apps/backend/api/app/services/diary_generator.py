import json
import logging
from datetime import date, datetime, timezone
from typing import Any
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.models.conversation import Conversation
from app.models.diary import DiaryEntry
from app.models.user import User
from packages.ai.factories.llm_factory import LLMFactory
from packages.ai.interfaces.llm import LLMMessage

logger = logging.getLogger(__name__)


class DiaryGeneratorService:
    """Service to aggregate today's conversation transcripts and invoke DeepSeek LLM to generate a structured DiaryEntry."""

    @staticmethod
    async def generate_today_diary(user_id: uuid.UUID, db: AsyncSession) -> DiaryEntry:
        today_date = date.today()

        # 1. Retrieve all conversations for today
        query = (
            select(Conversation)
            .options(selectinload(Conversation.messages))
            .where(
                Conversation.user_id == user_id,
                func.date(Conversation.started_at) == today_date,
            )
            .order_by(Conversation.started_at.asc())
        )
        res = await db.execute(query)
        today_convs = res.scalars().all()

        # 2. Extract and format all user & assistant messages chronologically
        all_formatted_msgs = []
        for conv in today_convs:
            sorted_msgs = sorted(conv.messages, key=lambda m: m.sequence_number) if conv.messages else []
            for msg in sorted_msgs:
                if msg.role in ("user", "assistant") and msg.content and msg.content.strip():
                    time_str = msg.created_at.strftime("%H:%M") if msg.created_at else "09:00"
                    all_formatted_msgs.append(f"[{time_str}] {msg.role.upper()}: {msg.content}")

        if not all_formatted_msgs:
            logger.info(f"ℹ️ [DIARY GENERATOR] No conversation messages found for user {user_id} on {today_date}. Returning default diary.")
            return await DiaryGeneratorService._upsert_default_diary(user_id, today_date, db)

        transcript_text = "\n".join(all_formatted_msgs)

        # 3. Formulate system & user prompt for LLM API
        system_prompt = LLMMessage(
            role="system",
            content=(
                "Anda adalah sistem analis kesehatan mental & konseling psikologi LUNA AI. "
                "Tugas Anda adalah menganalisis seluruh transkrip percakapan harian pengguna hari ini, "
                "lalu menghasilkan output JSON VALID HANYA TANPA MARKDOWN (tanpa ```json atau teks tambahan lainnya).\n\n"
                "Format JSON yang HARUS dihasilkan secara presisi:\n"
                "{\n"
                '  "title": "<Judul Jurnal Utama 4-8 Kata Bahasa Indonesia, contoh: Refleksi Harian & Evaluasi Ujian>",\n'
                '  "summary": "<Ringkasan kumulatif emosi & poin utama percakapan 2-3 kalimat>",\n'
                '  "content": "<Narasi detail kejadian dan refleksi emosional sepanjang hari>",\n'
                '  "mood_tag": "<Tag mood dominan misal: Tenang & Nyaman 🌿 atau Cemas & Stres 😟 atau Bahagia & Puas 😃>",\n'
                '  "mood_emoji": "<Emoji 1 karakter misal: 🌿 atau 😟 atau 😃>",\n'
                '  "ai_insight": "<1-2 kalimat wawasan evaluasi psikologis AI terhadap kondisi emosional pengguna>",\n'
                '  "emotional_reflection": "<1-2 kalimat refleksi positif & rekomendasi penenangan diri>",\n'
                '  "important_events": ["<[HH:MM] Peristiwa/masalah penting 1>", "<[HH:MM] Peristiwa 2>"]\n'
                "}"
            ),
        )

        user_prompt = LLMMessage(
            role="user",
            content=f"Analisislah kumulatif transkrip percakapan harian berikut ({today_date.strftime('%d %b %Y')}):\n\n{transcript_text}",
        )

        try:
            llm_provider = LLMFactory.get_provider()
            full_response_list = []
            async for token in llm_provider.stream_response([system_prompt, user_prompt]):
                full_response_list.append(token)

            raw_output = "".join(full_response_list).strip()
            if raw_output.startswith("```"):
                raw_output = raw_output.split("```")[1]
                if raw_output.startswith("json"):
                    raw_output = raw_output[4:]
            raw_output = raw_output.strip()

            parsed = json.loads(raw_output)
            logger.info(f"📖 [DIARY GENERATOR SUCCESS] Generated AI diary for user {user_id} on {today_date}: '{parsed.get('title')}'")

            return await DiaryGeneratorService._save_parsed_diary(user_id, today_date, parsed, db)

        except Exception as e:
            logger.error(f"⚠️ [DIARY GENERATOR EXCEPTION] Failed to generate AI diary via LLM: {e}. Falling back to default.")
            return await DiaryGeneratorService._upsert_default_diary(user_id, today_date, db)

    @staticmethod
    async def _save_parsed_diary(
        user_id: uuid.UUID, entry_date: date, data: dict[str, Any], db: AsyncSession
    ) -> DiaryEntry:
        title = data.get("title") or f"Jurnal Refleksi - {entry_date.strftime('%d %b %Y')}"
        summary = data.get("summary") or "Kumulatif percakapan suara & teks hari ini."
        content = data.get("content") or summary
        mood_tag = data.get("mood_tag") or "Tenang & Nyaman 🌿"
        mood_emoji = data.get("mood_emoji") or "🌿"
        ai_insight = data.get("ai_insight") or "Kondisi emosional pengguna terpantau stabil."
        emotional_reflection = data.get("emotional_reflection") or "Pengguna merasa lebih tenang setelah berdialog bersama LUNA."
        important_events = data.get("important_events") or [f"[{datetime.now().strftime('%H:%M')}] Sesi Percakapan LUNA"]

        # Check existing diary entry for today
        query = select(DiaryEntry).where(DiaryEntry.user_id == user_id, DiaryEntry.entry_date == entry_date).order_by(DiaryEntry.created_at.desc())
        res = await db.execute(query)
        diary = res.scalars().first()

        if not diary:
            diary = DiaryEntry(
                user_id=user_id,
                entry_date=entry_date,
                title=title,
                summary=summary,
                content=content,
                mood_tag=mood_tag,
                mood_emoji=mood_emoji,
                ai_insight=ai_insight,
                emotional_reflection=emotional_reflection,
                important_events=important_events,
            )
            db.add(diary)
        else:
            diary.title = title
            diary.summary = summary
            diary.content = content
            diary.mood_tag = mood_tag
            diary.mood_emoji = mood_emoji
            diary.ai_insight = ai_insight
            diary.emotional_reflection = emotional_reflection
            diary.important_events = important_events

        await db.commit()
        await db.refresh(diary)
        return diary

    @staticmethod
    async def _upsert_default_diary(user_id: uuid.UUID, entry_date: date, db: AsyncSession) -> DiaryEntry:
        default_data = {
            "title": f"Refleksi Harian - {entry_date.strftime('%d %b %Y')}",
            "summary": "Sesi percakapan hari ini berjalan dengan baik dan memberikan ketenangan emosional.",
            "content": "Pengguna telah berinteraksi dengan LUNA AI untuk merefleksikan perasaan dan aktivitas hari ini.",
            "mood_tag": "Tenang & Nyaman 🌿",
            "mood_emoji": "🌿",
            "ai_insight": "Pengguna merasa didengarkan dan mulai merasa lebih rileks selama percakapan.",
            "emotional_reflection": "Refleksi emosi menunjukkan respon positif terhadap konseling LUNA.",
            "important_events": [f"[{datetime.now().strftime('%H:%M')}] Sesi Panggilan Suara & Chat LUNA"],
        }
        return await DiaryGeneratorService._save_parsed_diary(user_id, entry_date, default_data, db)
