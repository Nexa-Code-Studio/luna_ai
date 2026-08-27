import logging
import uuid
from decimal import Decimal
from typing import Any, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.models.safety import EmotionAnalysis

logger = logging.getLogger(__name__)


class MLEmotionDetectorService:
    """Service placeholder untuk ML/AI Emotion Detection Model (emotion2vec/emotion2vec_plus_large).
    
    Model Reference: https://huggingface.co/emotion2vec/emotion2vec_plus_large
    Multilingual Audio Emotion Recognition (~300M parameters).
    
    Mapping Class Index (0 to 8):
    0: angry      (Marah 😡)
    1: disgusted  (Jijik/Muak 🤢)
    2: fearful    (Cemas/Takut 😰)
    3: happy      (Bahagia/Senang 😃)
    4: neutral    (Netral/Tenang 😌)
    5: other      (Lainnya 🌫️)
    6: sad        (Sedih 😢)
    7: surprised  (Terkejut 😲)
    8: unknown    (Tidak Diketahui ❓)
    """

    # 9 Kelas Emosi Resmi dari emotion2vec_plus_large
    EMOTION_2VEC_CLASSES = {
        0: {"name": "angry", "label": "Marah", "emoji": "😡", "color": "#FF7675"},
        1: {"name": "disgusted", "label": "Jijik / Muak", "emoji": "🤢", "color": "#55EFC4"},
        2: {"name": "fearful", "label": "Cemas & Takut", "emoji": "😰", "color": "#6C63FF"},
        3: {"name": "happy", "label": "Bahagia & Senang", "emoji": "😃", "color": "#FFE6A7"},
        4: {"name": "neutral", "label": "Netral & Tenang", "emoji": "😌", "color": "#4ECDC4"},
        5: {"name": "other", "label": "Lainnya", "emoji": "🌫️", "color": "#B2BEC3"},
        6: {"name": "sad", "label": "Sedih", "emoji": "😢", "color": "#74B9FF"},
        7: {"name": "surprised", "label": "Terkejut", "emoji": "😲", "color": "#A29BFE"},
        8: {"name": "unknown", "label": "Tidak Diketahui", "emoji": "❓", "color": "#DFE6E9"},
    }

    @staticmethod
    async def predict_message_emotion(
        text: str,
        audio_bytes: Optional[bytes] = None,
    ) -> dict[str, Any]:
        """[PLACEHOLDER INFRENSI MODEL ML: emotion2vec_plus_large]
        
        Menerima data audio raw bytes dan/atau teks ucapan pengguna,
        lalu mengembalikan hasil klasifikasi 9 kelas emosi `emotion2vec_plus_large`
        berformat Dictionary/JSON yang akan disimpan ke kolom `emotions` (JSONB) di PostgreSQL.

        Args:
            text (str): Teks ucapan pengguna dari STT.
            audio_bytes (Optional[bytes]): Data audio WAV/PCM (16kHz mono) dari mikrofon HP.

        Returns:
            dict[str, Any]: Dictionary JSON berstruktur:
            {
                "model_name": "emotion2vec_plus_large",
                "primary_emotion": "happy",
                "secondary_emotion": "neutral",
                "confidence": 0.88,
                "intensity": 0.79,
                "raw_scores": [0.01, 0.00, 0.02, 0.88, 0.06, 0.01, 0.01, 0.01, 0.00],
                "emotions_breakdown": [
                    {"class_id": 3, "name": "happy", "label": "Bahagia & Senang", "emoji": "😃", "percent": 0.88, "color": "#FFE6A7"},
                    {"class_id": 4, "name": "neutral", "label": "Netral & Tenang", "emoji": "😌", "percent": 0.06, "color": "#4ECDC4"},
                    {"class_id": 2, "name": "fearful", "label": "Cemas & Takut", "emoji": "😰", "percent": 0.02, "color": "#6C63FF"},
                    {"class_id": 0, "name": "angry", "label": "Marah", "emoji": "😡", "percent": 0.01, "color": "#FF7675"},
                    {"class_id": 6, "name": "sad", "label": "Sedih", "emoji": "😢", "percent": 0.01, "color": "#74B9FF"},
                    {"class_id": 5, "name": "other", "label": "Lainnya", "emoji": "🌫️", "percent": 0.01, "color": "#B2BEC3"},
                    {"class_id": 7, "name": "surprised", "label": "Terkejut", "emoji": "😲", "percent": 0.01, "color": "#A29BFE"},
                    {"class_id": 1, "name": "disgusted", "label": "Jijik / Muak", "emoji": "🤢", "percent": 0.00, "color": "#55EFC4"},
                    {"class_id": 8, "name": "unknown", "label": "Tidak Diketahui", "emoji": "❓", "percent": 0.00, "color": "#DFE6E9"}
                ]
            }
        """
        logger.info(f"🧠 [EMOTION2VEC INFERENCE]: Processing input text len={len(text)}, audio_bytes={len(audio_bytes) if audio_bytes else 0}")

        # =========================================================================
        # TODO DEVELOPER ML: Panggil Model emotion2vec_plus_large di sini.
        # Example FunASR / ModelScope / HuggingFace inference:
        #   from funasr import AutoModel
        #   model = AutoModel(model="emotion2vec_plus_large")
        #   res = model.generate(audio_bytes)
        # =========================================================================

        # DEFAULT FALLBACK SIMULATION (Akan digantikan oleh output model emotion2vec_plus_large Anda)
        text_lower = text.lower()
        if any(w in text_lower for w in ["senang", "bahagia", "suka", "terima kasih", "lega"]):
            primary = "happy"
            primary_id = 3
            confidence = 0.88
        elif any(w in text_lower for w in ["cemas", "takut", "khawatir", "stres", "panik"]):
            primary = "fearful"
            primary_id = 2
            confidence = 0.82
        elif any(w in text_lower for w in ["sedih", "kecewa", "menangis", "lelah"]):
            primary = "sad"
            primary_id = 6
            confidence = 0.78
        elif any(w in text_lower for w in ["marah", "kesal", "benci", "jengkel"]):
            primary = "angry"
            primary_id = 0
            confidence = 0.80
        else:
            primary = "neutral"
            primary_id = 4
            confidence = 0.90

        emotions_breakdown = []
        for cid, meta in MLEmotionDetectorService.EMOTION_2VEC_CLASSES.items():
            pct = confidence if cid == primary_id else (0.05 if cid == 4 else 0.01)
            emotions_breakdown.append({
                "class_id": cid,
                "name": meta["name"],
                "label": meta["label"],
                "emoji": meta["emoji"],
                "percent": round(pct, 2),
                "color": meta["color"],
            })

        return {
            "model_name": "emotion2vec_plus_large",
            "primary_emotion": primary,
            "secondary_emotion": "neutral" if primary != "neutral" else "happy",
            "confidence": confidence,
            "intensity": round(confidence * 0.9, 2),
            "emotions_breakdown": emotions_breakdown,
        }

    @staticmethod
    async def save_emotion_to_db(
        message_id: uuid.UUID,
        analysis_result: dict[str, Any],
        db: AsyncSession,
    ) -> EmotionAnalysis:
        """Menyimpan hasil prediksi emosi per-pesan langsung ke tabel PostgreSQL `emotion_analyses`.

        Args:
            message_id (uuid.UUID): ID unik dari baris pesan di tabel `messages`.
            analysis_result (dict[str, Any]): Dictionary hasil return dari `predict_message_emotion`.
            db (AsyncSession): Sesi koneksi SQLAlchemy database async.

        Returns:
            EmotionAnalysis: Instance model yang baru saja disimpan ke database PostgreSQL.
        """
        record = EmotionAnalysis(
            message_id=message_id,
            primary_emotion=analysis_result.get("primary_emotion"),
            secondary_emotion=analysis_result.get("secondary_emotion"),
            confidence=Decimal(str(analysis_result.get("confidence", 0.0))),
            intensity=Decimal(str(analysis_result.get("intensity", 0.0))),
            emotions=analysis_result.get("emotions_breakdown"),
        )
        db.add(record)
        await db.commit()
        await db.refresh(record)
        logger.info(f"💾 [EMOTION SAVED TO DB]: Successfully saved emotion analysis for message_id={message_id}")
        return record

    @staticmethod
    def aggregate_session_emotions(messages_emotions: list[list[dict[str, Any]]]) -> list[dict[str, Any]]:
        """Mengkalkulasi rata-rata matematis dari distribusi 9 emosi per-pesan pengguna
        untuk menghasilkan persentase kumulatif akhir pada Diary/Sesi.

        Args:
            messages_emotions (list[list[dict[str, Any]]]): List dari emotions_breakdown per-pesan user.

        Returns:
            list[dict[str, Any]]: Persentase rata-rata 9 emosi yang sudah diurutkan dari persentase tertinggi.
        """
        if not messages_emotions:
            return [
                {"class_id": 4, "name": "neutral", "label": "Netral & Tenang", "emoji": "😌", "percent": 0.85, "color": "#4ECDC4"},
                {"class_id": 3, "name": "happy", "label": "Bahagia & Senang", "emoji": "😃", "percent": 0.15, "color": "#FFE6A7"},
            ]

        totals: dict[int, float] = {cid: 0.0 for cid in MLEmotionDetectorService.EMOTION_2VEC_CLASSES}
        count = len(messages_emotions)

        for single_msg_breakdown in messages_emotions:
            if isinstance(single_msg_breakdown, list):
                for item in single_msg_breakdown:
                    cid = item.get("class_id")
                    pct = item.get("percent", 0.0)
                    if cid in totals:
                        totals[cid] += float(pct)

        aggregated = []
        for cid, meta in MLEmotionDetectorService.EMOTION_2VEC_CLASSES.items():
            avg_pct = round(totals[cid] / count, 2)
            if avg_pct > 0:
                aggregated.append({
                    "class_id": cid,
                    "name": meta["name"],
                    "label": meta["label"],
                    "emoji": meta["emoji"],
                    "percent": avg_pct,
                    "color": meta["color"],
                })

        # Sort descending by percent
        aggregated.sort(key=lambda x: x["percent"], reverse=True)
        return aggregated
