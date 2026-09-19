import asyncio
from datetime import date, datetime, UTC
import logging
from sqlalchemy import select

from app.db.session import AsyncSessionLocal, engine
from app.models.base import BaseModel
from app.models.conversation import Conversation, Message
from app.models.diary import DiaryEntry
from app.models.coping_activity import CopingActivity, UserActivityCompletion
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

        # 4b. Seed Evidence-Based Coping Activities (Condition-Specific)
        query_coping = select(CopingActivity)
        res_coping = await session.execute(query_coping)
        existing_coping = res_coping.scalars().all()

        if not existing_coping:
            c1 = CopingActivity(
                title="Teknik Grounding 5-4-3-2-1",
                category="CBT Somatis",
                target_condition="anxiety",
                duration="5 Menit",
                difficulty="Pemula",
                description="Mengaktifkan panca indra untuk memutus siklus kecemasan dan membawa kesadaran kembali ke saat ini.",
                instructions=[
                    "Perhatikan 5 benda yang bisa kamu lihat di sekitarmu.",
                    "Rasakan 4 hal yang bisa kamu sentuh atau rasakan fisiknya.",
                    "Dengarkan 3 suara berbeda di lingkunganmu.",
                    "Kenali 2 aroma yang tercium saat ini.",
                    "Rasakan 1 cita rasa di lidahmu.",
                ],
                rationale="Membantu menstabilkan amigdala yang hiperaktif dan mengalihkan fokus dari pikiran katastrofik ke realitas sensorik.",
                icon_name="accessibility_new",
                is_active=True,
            )
            c2 = CopingActivity(
                title="Box Breathing (Pernapasan Kotak)",
                category="Mindfulness",
                target_condition="anxiety",
                duration="4 Menit",
                difficulty="Pemula",
                description="Latihan pernapasan berirama 4 detik untuk meredakan denyut jantung dan kepanikan.",
                instructions=[
                    "Tarik napas perlahan melalui hidung selama 4 detik.",
                    "Tahan napasmu selama 4 detik dengan tenang.",
                    "Hembuskan napas perlahan melalui mulut selama 4 detik.",
                    "Tahan ruang kosong di paru-parumu selama 4 detik.",
                    "Ulangi siklus ini sebanyak 4 hingga 6 kali.",
                ],
                rationale="Menyeimbangkan sistem saraf otonom dan menurunkan kadar hormon stres secara instan.",
                icon_name="air",
                is_active=True,
            )
            c3 = CopingActivity(
                title="Latihan Pernapasan 4-7-8",
                category="Mindfulness",
                target_condition="stress",
                duration="5 Menit",
                difficulty="Pemula",
                description="Teknik pernapasan relaksasi mendalam untuk mengaktifkan sistem saraf parasimpatik.",
                instructions=[
                    "Buang napas sepenuhnya melalui mulut.",
                    "Tarik napas tenang lewat hidung dalam 4 detik.",
                    "Tahan napasmu selama 7 detik.",
                    "Hembuskan kuat-kuat melalui mulut dalam 8 detik.",
                    "Ulangi hingga 4 siklus pernapasan.",
                ],
                rationale="Memperlambat detak jantung dan meredakan ketegangan otot akibat stres kronis.",
                icon_name="spa",
                is_active=True,
            )
            c4 = CopingActivity(
                title="Progressive Muscle Relaxation (PMR)",
                category="Somatis",
                target_condition="stress",
                duration="7 Menit",
                difficulty="Menengah",
                description="Menegangkan dan melemaskan kelompok otot secara bergantian untuk melepaskan beban somatis.",
                instructions=[
                    "Duduk atau berbaringlah dengan nyaman.",
                    "Kepalkan kedua tangan kuat-kuat selama 5 detik, lalu lepaskan seketika.",
                    "Tarik bahu ke arah telinga selama 5 detik, lalu lepaskan dan rasakan kelegaannya.",
                    "Kencangkan otot betis dan kaki selama 5 detik, lalu rilekskan.",
                    "Rasakan perbedaan antara rasa tegang dan rasa rileks.",
                ],
                rationale="Memecah akumulasi ketegangan fisik somatis yang sering tidak disadari oleh tubuh.",
                icon_name="self_improvement",
                is_active=True,
            )
            c5 = CopingActivity(
                title="Aktivasi Perilaku: Jalan Pagi 10 Menit",
                category="Aktivasi Perilaku",
                target_condition="depression",
                duration="10 Menit",
                difficulty="Pemula",
                description="Aktivitas fisik ringan untuk merangsang produksi dopamin dan endorfin secara alami.",
                instructions=[
                    "Kenakan pakaian santai dan sepatu yang nyaman.",
                    "Berjalanlah santai di luar ruangan atau sekitar rumah selama 10 menit.",
                    "Biarkan sinar matahari pagi menyentuh kulitmu.",
                    "Tidak perlu terburu-buru, nikmati setiap langkahmu.",
                ],
                rationale="Mengatasi kelembaman (inertia) dan anhedonia dengan memicu pelepasan neurotransmiter penstabil suasana hati.",
                icon_name="directions_walk",
                is_active=True,
            )
            c6 = CopingActivity(
                title="Catatan Tiga Hal Syukur (Gratitude)",
                category="Refleksi Kognitif",
                target_condition="depression",
                duration="5 Menit",
                difficulty="Pemula",
                description="Menuliskan 3 hal kecil yang bermakna untuk mengimbangi bias negatif kognitif.",
                instructions=[
                    "Ambil buku catatan atau buka aplikasi Luna.",
                    "Pikirkan 3 hal kecil yang memberi kenyamanan hari ini.",
                    "Tuliskan mengapa hal tersebut membuatmu merasa bersyukur.",
                    "Resapi perasaan hangat yang muncul di hatimu.",
                ],
                rationale="Membiasakan otak melatih perhatian selektif terhadap aspek positif kehidupan.",
                icon_name="edit_note",
                is_active=True,
            )
            c7 = CopingActivity(
                title="Jeda Digital & Istirahat Mata",
                category="Self-care",
                target_condition="general",
                duration="15 Menit",
                difficulty="Pemula",
                description="Menjauh sejenak dari layar gadget untuk memulihkan kelelahan sensorik mental.",
                instructions=[
                    "Matikan layar ponsel dan laptopmu.",
                    "Tatap pemandangan jauh atau tanaman hijau selama beberapa saat.",
                    "Minum segelas air putih dengan perlahan dan sadar.",
                    "Regangkan otot leher dan punggungmu.",
                ],
                rationale="Meredakan kelelahan sensorik visual dan kognitif akibat paparan informasi berlebih.",
                icon_name="phonelink_off",
                is_active=True,
            )
            c8 = CopingActivity(
                title="Mindful Body Scan Singkat",
                category="Mindfulness",
                target_condition="general",
                duration="5 Menit",
                difficulty="Pemula",
                description="Memeriksa kondisi tubuh dari kepala hingga kaki dengan penuh penerimaan.",
                instructions=[
                    "Duduk tegak namun rileks, pejamkan matamu.",
                    "Arahkan perhatianmu ke puncak kepala, dahi, hingga rahang.",
                    "Turunkan perhatian ke bahu, dada, perut, dan punggung.",
                    "Lanjutkan hingga ujung jari kaki.",
                    "Sambut sensasi apa pun tanpa menghakimi.",
                ],
                rationale="Meningkatkan kesadaran interoseptif (hubungan tubuh dan pikiran) untuk menjaga kestabilan emosi.",
                icon_name="psychology",
                is_active=True,
            )
            session.add_all([c1, c2, c3, c4, c5, c6, c7, c8])
            await session.commit()
            logger.info("Seeded Evidence-Based Coping Activities.")

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
