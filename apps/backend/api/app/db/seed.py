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

        # 3. Seed Diary Entries (Skipped: Real diaries are generated automatically via AI)
        logger.info("Skipping dummy diary seeding to use dynamic AI entries.")

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
