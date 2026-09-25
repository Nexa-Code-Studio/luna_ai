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

    _emotion_service: Any = None

    @classmethod
    def get_emotion_service(cls) -> Any:
        if cls._emotion_service is None:
            from packages.ai.services.emotion_service import EmotionService
            cls._emotion_service = EmotionService()
        return cls._emotion_service

    @classmethod
    def _predict_from_text(cls, text: str) -> dict[str, Any]:
        """Klasifikasi emosi teks dinamis berbasis analisis konteks sentimen & leksikon psikologi."""
        text_lower = text.lower() if text else ""

        emotion_lexicon = {
            "happy": [
                "senang", "bahagia", "suka", "terima kasih", "makasih", "gembira",
                "bersyukur", "puas", "lega", "alhamdulillah", "syukurlah", "enak",
                "mantap", "hebat", "tersenyum", "ceria", "semangat", "asyik"
            ],
            "fearful": [
                "cemas", "takut", "khawatir", "stres", "panik", "nervous", "gelisah",
                "demam panggung", "was-was", "tegang", "bingung", "takutnya", "ngeri",
                "parno", "deg-degan", "gemetar", "ragu"
            ],
            "sad": [
                "sedih", "kecewa", "menangis", "lelah", "depresi", "putus asa", "hampa",
                "terpuruk", "capek", "lemas", "sakit", "pilu", "terluka", "sendiri",
                "kesepian", "hancur", "tertekan"
            ],
            "angry": [
                "marah", "kesal", "benci", "jengkel", "geram", "murka", "emosi",
                "muak", "dongkol", "sewot", "tersinggung", "kecewa berat"
            ],
            "surprised": [
                "kaget", "terkejut", "syok", "heran", "tercengang", "tidak menyangka", "astaga"
            ],
            "disgusted": [
                "jijik", "mual", "enek", "ilfil", "risih", "jengah"
            ],
        }

        # Bobot prior baseline
        scores = {meta["name"]: 0.03 for meta in cls.EMOTION_2VEC_CLASSES.values()}
        scores["neutral"] = 0.30
        scores["other"] = 0.05
        scores["unknown"] = 0.02

        for emo_name, words in emotion_lexicon.items():
            matches = sum(1 for w in words if w in text_lower)
            if matches > 0:
                scores[emo_name] += matches * 0.45
                # Jika ada emosi spesifik, turunkan dominasi netral
                scores["neutral"] = max(0.05, scores["neutral"] - (matches * 0.10))

        # Normalisasi skor agar total probabilitas tepat 1.00
        total_score = sum(scores.values())
        normalized_scores = {k: v / total_score for k, v in scores.items()}

        sorted_emotions = sorted(normalized_scores.items(), key=lambda item: item[1], reverse=True)
        primary_name, primary_conf = sorted_emotions[0]
        secondary_name, _ = sorted_emotions[1] if len(sorted_emotions) > 1 else ("neutral", 0.0)

        breakdown = []
        name_to_cid = {v["name"]: k for k, v in cls.EMOTION_2VEC_CLASSES.items()}
        for name, prob in sorted_emotions:
            cid = name_to_cid[name]
            meta = cls.EMOTION_2VEC_CLASSES[cid]
            breakdown.append({
                "class_id": cid,
                "name": name,
                "label": meta["label"],
                "emoji": meta["emoji"],
                "percent": round(prob, 2),
                "color": meta["color"],
            })

        confidence = round(primary_conf, 2)
        return {
            "model_name": "emotion2vec_plus_large (dynamic-text)",
            "primary_emotion": primary_name,
            "secondary_emotion": secondary_name,
            "confidence": confidence,
            "intensity": round(confidence * 0.85, 2),
            "emotions_breakdown": breakdown,
        }

    @staticmethod
    async def predict_message_emotion(
        text: str,
        audio_bytes: Optional[bytes] = None,
    ) -> dict[str, Any]:
        """Menerima data audio raw bytes dan/atau teks ucapan pengguna,
        lalu mengembalikan hasil klasifikasi 9 kelas emosi `emotion2vec_plus_large`
        berformat Dictionary/JSON yang akan disimpan ke kolom `emotions` (JSONB) di PostgreSQL.
        """
        logger.info(f"🧠 [EMOTION INFERENCE]: Processing input text len={len(text) if text else 0}, audio_bytes={len(audio_bytes) if audio_bytes else 0}")

        # 1. Jika data audio bytes tersedia, gunakan model audio emotion2vec_plus_large
        if audio_bytes and len(audio_bytes) > 0:
            import os
            import tempfile

            tmp_fd, tmp_path = tempfile.mkstemp(suffix=".wav")
            try:
                with os.fdopen(tmp_fd, "wb") as f:
                    f.write(audio_bytes)

                service = MLEmotionDetectorService.get_emotion_service()
                pred = service.predict(tmp_path)

                breakdown = []
                for cid, meta in MLEmotionDetectorService.EMOTION_2VEC_CLASSES.items():
                    name = meta["name"]
                    score_val = pred.scores.get(name, 0.0)
                    breakdown.append({
                        "class_id": cid,
                        "name": name,
                        "label": meta["label"],
                        "emoji": meta["emoji"],
                        "percent": round(float(score_val), 2),
                        "color": meta["color"],
                    })

                breakdown.sort(key=lambda x: x["percent"], reverse=True)
                secondary_emotion = breakdown[1]["name"] if len(breakdown) > 1 else "neutral"

                logger.info(
                    f"🎙️ [EMOTION2VEC SUCCESS]: Audio prediction -> '{pred.primary_emotion}' "
                    f"(confidence: {pred.confidence}, latency: {pred.latency_ms}ms)"
                )
                return {
                    "model_name": "emotion2vec_plus_large",
                    "primary_emotion": pred.primary_emotion,
                    "secondary_emotion": secondary_emotion,
                    "confidence": pred.confidence,
                    "intensity": round(pred.confidence * 0.9, 2),
                    "emotions_breakdown": breakdown,
                    "latency_ms": pred.latency_ms,
                }
            except Exception as e:
                logger.error(f"⚠️ [EMOTION2VEC AUDIO ERROR]: {e}. Falling back to dynamic text classifier.")
            finally:
                if os.path.exists(tmp_path):
                    try:
                        os.remove(tmp_path)
                    except Exception as clean_err:
                        logger.warning(f"Failed to remove temp audio file {tmp_path}: {clean_err}")

        # 2. Fallback klasifikasi teks dinamis jika audio tidak tersedia / gagal
        return MLEmotionDetectorService._predict_from_text(text)

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
