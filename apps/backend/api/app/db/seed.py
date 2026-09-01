import asyncio
from datetime import date, datetime, UTC
import logging
from sqlalchemy import select

from app.db.session import AsyncSessionLocal, engine
from app.models.base import BaseModel
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.enums import ConversationStatus, MessageType
from app.models.recommendation import RecommendationItem
from app.models.user import EmergencyContact, User

logger = logging.getLogger(__name__)


async def seed_master_data() -> User:
    """Seed comprehensive initial data for mobile app consumption."""
    logger.info("Initializing database tables...")
    async with engine.begin() as conn:
        await conn.run_sync(BaseModel.metadata.create_all)

    async with AsyncSessionLocal() as session:
        # 1. Seed Master User (Samsul)
        query_user = select(User).where(User.email == "samsul@gmail.com")
        res_user = await session.execute(query_user)
        user = res_user.scalar_one_or_none()

        # Check for legacy user.luna@gmail.com to migrate/update
        if not user:
            query_old = select(User).where(User.email == "user.luna@gmail.com")
            res_old = await session.execute(query_old)
            old_user = res_old.scalar_one_or_none()
            if old_user:
                user = old_user
                user.email = "samsul@gmail.com"
                user.username = "samsul"
                user.display_name = "Samsul"
                user.password_hash = "password123"
                await session.commit()
                await session.refresh(user)
                logger.info(f"Migrated existing user to Samsul: samsul@gmail.com ({user.id})")

        if not user:
            user = User(
                email="samsul@gmail.com",
                username="samsul",
                display_name="Samsul",
                password_hash="password123",
                is_active=True,
                is_verified=True,
            )
            session.add(user)
            await session.commit()
            await session.refresh(user)
            logger.info(f"Seeded Master User: samsul@gmail.com ({user.id})")
        else:
            user.display_name = "Samsul"
            user.username = "samsul"
            await session.commit()
            logger.info(f"Existing Master User updated: {user.email}")

        # 2. Seed Emergency Contacts
        query_contacts = select(EmergencyContact).where(EmergencyContact.user_id == user.id)
        res_contacts = await session.execute(query_contacts)
        existing_contacts = res_contacts.scalars().all()

        if not existing_contacts:
            c1 = EmergencyContact(
                user_id=user.id,
                name="Ibu (Siti Rahma)",
                relationship="Ibu",
                phone_number="0812-3456-7890",
                is_primary=True,
            )
            c2 = EmergencyContact(
                user_id=user.id,
                name="Dr. Handoko (Psikiater)",
                relationship="Dokter",
                phone_number="0811-9876-5432",
                is_primary=False,
            )
            session.add_all([c1, c2])
            await session.commit()
            logger.info("Seeded Emergency Contacts.")

        # 3. Seed Full Diary Entries History (including 28 Agustus 2026 Emergency Entry)
        target_entries = [
            {
                "entry_date": date(2026, 9, 1),
                "title": "Jurnal Refleksi Hari Ini",
                "summary": "Samsul merasa lebih semangat dan positif setelah berdiskusi mengenai target pribadi dan meditasi pagi bersama LUNA.",
                "content": "Catatan harian mengenai target positif dan meditasi.",
                "mood_tag": "Bahagia 😃",
                "mood_emoji": "😃",
                "ai_insight": "Progres emosional Samsul menunjukkan peningkatan kebahagiaan dan motivasi positif.",
                "emotional_reflection": "Merasa optimis menghadapi tantangan hari ini.",
                "important_events": ["[Sesi #1] Afirmasi positif pagi dan perencanaan aktivitas produktif."],
            },
            {
                "entry_date": date(2026, 8, 31),
                "title": "Catatan Refleksi Emosi Harian",
                "summary": "Samsul merasakan ketenangan setelah menyelesaikan sesi konsultasi mengenai manajemen waktu dan relaksasi pikiran.",
                "content": "Diskusi relaksasi emosional.",
                "mood_tag": "Tenang 😌",
                "mood_emoji": "😌",
                "ai_insight": "Kondisi emosional Samsul tergolong stabil.",
                "emotional_reflection": "Merasa lebih lega dan siap melanjutkan aktivitas.",
                "important_events": ["[Sesi #1] Refleksi mengenai rutinitas harian dan teknik olah napas."],
            },
            {
                "entry_date": date(2026, 8, 28),
                "title": "Jurnal Emosional Krisis — Samsul",
                "summary": "Samsul mengutarakan rasa kecemasan dan kelelahan mental ekstrem terkait beban kerja dan kondisi krisis. Terdeteksi indikasi krisis emosional tinggi.",
                "content": "Sesi konseling mengindikasikan kecemasan mendalam dan risiko tinggi emosional.",
                "mood_tag": "Darurat 🚨",
                "mood_emoji": "🚨",
                "ai_insight": "Luna AI mengaktifkan mode de-eskalasi dan menyajikan rujukan kontak krisis darurat (Hotline 119 ext 8).",
                "emotional_reflection": "Samsul menganjurkan diri untuk beristirahat penuh dan menghubungi Kontak Darurat Utama atau Konselor Profesional.",
                "important_events": [
                    "[Sesi #1] Samsul menyampaikan keluhan kelelahan fisik dan kecemasan mendalam.",
                    "[Sesi #2] Terdeteksi puncak stres emosional tinggi — Protokol Krisis dipicu.",
                ],
            },
        ]

        for entry_data in target_entries:
            query_d = select(DiaryEntry).where(
                DiaryEntry.user_id == user.id,
                DiaryEntry.entry_date == entry_data["entry_date"],
            )
            res_d = await session.execute(query_d)
            existing_d = res_d.scalar_one_or_none()

            if not existing_d:
                new_d = DiaryEntry(user_id=user.id, **entry_data)
                session.add(new_d)
                await session.commit()
                logger.info(f"Seeded Diary Entry for date {entry_data['entry_date']}: {entry_data['title']}")

        # 4. Seed Recommendations
        query_recs = select(RecommendationItem)
        res_recs = await session.execute(query_recs)
        existing_recs = res_recs.scalars().all()

        if not existing_recs:
            r1 = RecommendationItem(
                user_id=user.id,
                title="Latihan Pernapasan 4-7-8",
                category="Mindfulness",
                duration="5 Menit",
                level="Pemula",
                description="Teknik pernapasan sederhana untuk menenangkan sistem saraf.",
                icon_name="air",
                is_completed=False,
            )
            r2 = RecommendationItem(
                user_id=user.id,
                title="Jurnal Ekspresif Malam",
                category="Refleksi",
                duration="10 Menit",
                level="Pemula",
                description="Tuliskan 3 hal yang kamu syukuri sebelum tidur.",
                icon_name="edit_note",
                is_completed=False,
            )
            r3 = RecommendationItem(
                user_id=user.id,
                title="Jeda Digital 15 Menit",
                category="Self-care",
                duration="15 Menit",
                level="Menengah",
                description="Matikan notifikasi dan istirahatkan mata dari layar HP.",
                icon_name="phonelink_off",
                is_completed=True,
            )
            session.add_all([r1, r2, r3])
            await session.commit()
            logger.info("Seeded Recommendations.")

        # 5. Conversations & Messages (Skipped: Start with 0 conversations for clean user state)
        logger.info("Skipping conversation seeding for 100% clean conversation history.")

        return user


def main() -> None:
    logging.basicConfig(level=logging.INFO)
    logger.info("Starting database seeding...")
    asyncio.run(seed_master_data())
    logger.info("Seeding completed successfully.")


if __name__ == "__main__":
    main()
