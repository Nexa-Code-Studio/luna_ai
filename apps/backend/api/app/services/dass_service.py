import logging
import uuid
from datetime import date
from typing import Any

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.dass import DASSAssessment
from app.schemas.dass import (
    DASSAssessmentResponse,
    DASSItemSchema,
    DASSItemUpdate,
)

logger = logging.getLogger(__name__)

OFFICIAL_DASS21_ITEMS: list[dict[str, Any]] = [
    {"item_id": 1, "scale": "stress", "question_text": "Saya merasa sulit untuk beristirahat atau menenangkan diri"},
    {"item_id": 2, "scale": "anxiety", "question_text": "Saya menyadari mulut saya terasa kering"},
    {"item_id": 3, "scale": "depression", "question_text": "Saya sama sekali tidak dapat merasakan perasaan positif"},
    {"item_id": 4, "scale": "anxiety", "question_text": "Saya mengalami kesulitan bernapas (misal napas cepat tanpa aktivitas fisik)"},
    {"item_id": 5, "scale": "depression", "question_text": "Saya merasa sulit berinisiatif untuk melakukan sesuatu"},
    {"item_id": 6, "scale": "stress", "question_text": "Saya cenderung bereaksi berlebihan terhadap suatu situasi"},
    {"item_id": 7, "scale": "anxiety", "question_text": "Saya mengalami gemetar (misalnya pada kedua tangan)"},
    {"item_id": 8, "scale": "stress", "question_text": "Saya merasa menghabiskan banyak energi karena terlalu cemas/gugup"},
    {"item_id": 9, "scale": "anxiety", "question_text": "Saya khawatir terhadap situasi di mana saya mungkin panik atau mempermalukan diri"},
    {"item_id": 10, "scale": "depression", "question_text": "Saya merasa tidak ada lagi hal baik yang bisa saya harapkan di masa depan"},
    {"item_id": 11, "scale": "stress", "question_text": "Saya mendapati diri saya mudah gelisah atau resah"},
    {"item_id": 12, "scale": "stress", "question_text": "Saya merasa sulit untuk rileks atau bersantai"},
    {"item_id": 13, "scale": "depression", "question_text": "Saya merasa sedih, murung, dan tertekan"},
    {"item_id": 14, "scale": "stress", "question_text": "Saya tidak sabar menghadapi hal yang menghambat apa yang sedang saya lakukan"},
    {"item_id": 15, "scale": "anxiety", "question_text": "Saya merasa hampir panik"},
    {"item_id": 16, "scale": "depression", "question_text": "Saya merasa tidak mampu antusias terhadap hal apa pun"},
    {"item_id": 17, "scale": "depression", "question_text": "Saya merasa bahwa diri saya tidak berharga"},
    {"item_id": 18, "scale": "stress", "question_text": "Saya merasa mudah tersinggung atau sensitif"},
    {"item_id": 19, "scale": "anxiety", "question_text": "Saya menyadari detak jantung saya berdegup kencang tanpa alasan fisik"},
    {"item_id": 20, "scale": "anxiety", "question_text": "Saya merasa takut tanpa alasan yang jelas"},
    {"item_id": 21, "scale": "depression", "question_text": "Saya merasa bahwa hidup ini tidak berarti"},
]


class DASSService:
    @staticmethod
    def generate_default_items() -> list[dict[str, Any]]:
        """Menghasilkan template 21 butir resmi dengan nilai default 0."""
        return [
            {
                "item_id": item["item_id"],
                "scale": item["scale"],
                "question_text": item["question_text"],
                "score": 0,
                "evidence": None,
                "reason": None,
                "confidence": 0.0,
                "is_user_edited": False,
            }
            for item in OFFICIAL_DASS21_ITEMS
        ]

    @staticmethod
    def calculate_scores(items: list[dict[str, Any]]) -> dict[str, Any]:
        """Menghitung total skor per subskala (dikali 2 sesuai norma DASS-21 Indonesia)

        dan mengklasifikasikan ke dalam kategori keparahan.
        """
        dep_raw = sum(int(it.get("score", 0)) for it in items if it.get("scale") == "depression")
        anx_raw = sum(int(it.get("score", 0)) for it in items if it.get("scale") == "anxiety")
        str_raw = sum(int(it.get("score", 0)) for it in items if it.get("scale") == "stress")

        dep_final = dep_raw * 2
        anx_final = anx_raw * 2
        str_final = str_raw * 2

        # Klasifikasi Depresi
        if dep_final >= 28:
            dep_sev = "Extremely Severe"
        elif dep_final >= 21:
            dep_sev = "Severe"
        elif dep_final >= 14:
            dep_sev = "Moderate"
        elif dep_final >= 10:
            dep_sev = "Mild"
        else:
            dep_sev = "Normal"

        # Klasifikasi Kecemasan
        if anx_final >= 20:
            anx_sev = "Extremely Severe"
        elif anx_final >= 15:
            anx_sev = "Severe"
        elif anx_final >= 10:
            anx_sev = "Moderate"
        elif anx_final >= 8:
            anx_sev = "Mild"
        else:
            anx_sev = "Normal"

        # Klasifikasi Stres
        if str_final >= 34:
            str_sev = "Extremely Severe"
        elif str_final >= 26:
            str_sev = "Severe"
        elif str_final >= 19:
            str_sev = "Moderate"
        elif str_final >= 15:
            str_sev = "Mild"
        else:
            str_sev = "Normal"

        return {
            "depression_score": dep_final,
            "anxiety_score": anx_final,
            "stress_score": str_final,
            "depression_severity": dep_sev,
            "anxiety_severity": anx_sev,
            "stress_severity": str_sev,
        }

    @staticmethod
    async def get_today_assessment(
        user_id: uuid.UUID,
        today_date: date,
        db: AsyncSession,
    ) -> DASSAssessmentResponse:
        """Mengambil asesmen DASS hari ini. Jika belum ada di database,

        mengembalikan form default 21 butir (skor 0) agar mobile tetap bisa menampilkan form.
        """
        stmt = select(DASSAssessment).where(
            DASSAssessment.user_id == user_id,
            DASSAssessment.assessed_date == today_date,
        )
        res = await db.execute(stmt)
        record = res.scalars().first()

        if record:
            return DASSAssessmentResponse.model_validate(record)

        # Kembalikan template belum dinilai
        default_items = DASSService.generate_default_items()
        scores = DASSService.calculate_scores(default_items)

        return DASSAssessmentResponse(
            id=None,
            user_id=user_id,
            conversation_id=None,
            assessed_date=today_date,
            depression_score=scores["depression_score"],
            anxiety_score=scores["anxiety_score"],
            stress_score=scores["stress_score"],
            depression_severity=scores["depression_severity"],
            anxiety_severity=scores["anxiety_severity"],
            stress_severity=scores["stress_severity"],
            verified_by_user=False,
            status="unassessed",
            items=[DASSItemSchema(**it) for it in default_items],
        )

    @staticmethod
    async def save_or_update_extracted(
        user_id: uuid.UUID,
        assessed_date: date,
        extracted_items: list[dict[str, Any]],
        conversation_id: uuid.UUID | None,
        db: AsyncSession,
    ) -> DASSAssessment:
        """Menyimpan atau memperbarui hasil ekstraksi AI ke tabel dass_assessments."""
        # Gabungkan dengan template lengkap 21 butir jika extracted_items belum lengkap
        item_map = {it["item_id"]: it for it in extracted_items}
        complete_items = []

        for default_it in DASSService.generate_default_items():
            i_id = default_it["item_id"]
            if i_id in item_map:
                complete_items.append(item_map[i_id])
            else:
                complete_items.append(default_it)

        scores = DASSService.calculate_scores(complete_items)

        stmt = select(DASSAssessment).where(
            DASSAssessment.user_id == user_id,
            DASSAssessment.assessed_date == assessed_date,
        )
        res = await db.execute(stmt)
        record = res.scalars().first()

        if record:
            # Jika user sudah memverifikasi manual, jangan ditimpa oleh auto_extracted
            if not record.verified_by_user:
                record.depression_score = scores["depression_score"]
                record.anxiety_score = scores["anxiety_score"]
                record.stress_score = scores["stress_score"]
                record.depression_severity = scores["depression_severity"]
                record.anxiety_severity = scores["anxiety_severity"]
                record.stress_severity = scores["stress_severity"]
                record.items = complete_items
                if conversation_id:
                    record.conversation_id = conversation_id
        else:
            record = DASSAssessment(
                user_id=user_id,
                conversation_id=conversation_id,
                assessed_date=assessed_date,
                depression_score=scores["depression_score"],
                anxiety_score=scores["anxiety_score"],
                stress_score=scores["stress_score"],
                depression_severity=scores["depression_severity"],
                anxiety_severity=scores["anxiety_severity"],
                stress_severity=scores["stress_severity"],
                verified_by_user=False,
                status="auto_extracted",
                items=complete_items,
            )
            db.add(record)

        await db.commit()
        await db.refresh(record)
        return record

    @staticmethod
    async def update_user_assessment(
        user_id: uuid.UUID,
        today_date: date,
        updates: list[DASSItemUpdate],
        db: AsyncSession,
    ) -> DASSAssessmentResponse:
        """Memperbarui skor butir yang diedit oleh pengguna, menghitung ulang skor subskala,

        dan menandai record sebagai 'verified'.
        """
        stmt = select(DASSAssessment).where(
            DASSAssessment.user_id == user_id,
            DASSAssessment.assessed_date == today_date,
        )
        res = await db.execute(stmt)
        record = res.scalars().first()

        if not record:
            # Jika belum ada record tersimpan di DB, buat baru dari default items
            base_items = DASSService.generate_default_items()
            record = DASSAssessment(
                user_id=user_id,
                assessed_date=today_date,
                verified_by_user=True,
                status="verified",
                items=base_items,
            )
            db.add(record)

        current_items = list(record.items) if record.items else DASSService.generate_default_items()
        item_dict_map = {it["item_id"]: it for it in current_items}

        for up in updates:
            if up.item_id in item_dict_map:
                item_dict_map[up.item_id]["score"] = up.score
                item_dict_map[up.item_id]["is_user_edited"] = True

        new_items = list(item_dict_map.values())
        scores = DASSService.calculate_scores(new_items)

        record.items = new_items
        record.depression_score = scores["depression_score"]
        record.anxiety_score = scores["anxiety_score"]
        record.stress_score = scores["stress_score"]
        record.depression_severity = scores["depression_severity"]
        record.anxiety_severity = scores["anxiety_severity"]
        record.stress_severity = scores["stress_severity"]
        record.verified_by_user = True
        record.status = "verified"

        await db.commit()
        await db.refresh(record)
        return DASSAssessmentResponse.model_validate(record)
