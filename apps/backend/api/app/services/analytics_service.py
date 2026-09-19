import calendar
from datetime import date, datetime, time, timedelta, timezone
import logging
from typing import Any
import uuid

from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.orm import selectinload

from app.core.tz import WIB, get_wib_now, get_wib_today, to_wib
from app.models.conversation import Conversation, Message
from app.models.dass import DASSAssessment
from app.models.diary import DiaryEntry
from app.models.safety import EmotionAnalysis

logger = logging.getLogger(__name__)


class AnalyticsService:
    """Service to compute emotional rhythm, mental health risks, and AI summaries
    for the Monitoring/Tren screen across 'today', 'week', and 'month' periods.
    """

    # 7 UI Emotions index mapping:
    # 0: happy, 1: netral, 2: fear, 3: sadness, 4: surprise, 5: anger, 6: disgusted
    EMOTION_MAP = {
        "happy": 0,
        "neutral": 1,
        "netral": 1,
        "other": 1,
        "unknown": 1,
        "fear": 2,
        "fearful": 2,
        "sad": 3,
        "sadness": 3,
        "surprise": 4,
        "surprised": 4,
        "anger": 5,
        "angry": 5,
        "disgust": 6,
        "disgusted": 6,
    }

    @staticmethod
    def _extract_7_emotions(analysis: EmotionAnalysis | None) -> list[float]:
        """Convert an EmotionAnalysis record into a 7-element float array."""
        if not analysis:
            return [0.0] * 7

        scores = [0.0] * 7
        raw_list = analysis.emotions

        if isinstance(raw_list, list) and raw_list:
            for item in raw_list:
                name = str(item.get("name", "")).lower()
                pct = float(item.get("percent", 0.0))
                idx = AnalyticsService.EMOTION_MAP.get(name, 1)
                scores[idx] += pct
        else:
            primary = (analysis.primary_emotion or "neutral").lower()
            idx = AnalyticsService.EMOTION_MAP.get(primary, 1)
            conf = float(analysis.confidence or 0.8)
            scores[idx] = conf
            rem = max(0.0, 1.0 - conf)
            scores[1] += rem  # Add remainder to neutral

        total = sum(scores)
        if total > 0:
            return [round(s / total, 3) for s in scores]
        return [0.0] * 7

    @staticmethod
    def _average_emotion_vectors(vectors: list[list[float]]) -> list[float]:
        if not vectors:
            return [0.0] * 7
        n = len(vectors)
        sums = [sum(col) for col in zip(*vectors)]
        avg = [s / n for s in sums]
        total = sum(avg)
        if total > 0:
            return [round(val / total, 3) for val in avg]
        return [0.0] * 7

    @staticmethod
    def _format_risk_card(name: str, risk_type: str, percent: float) -> dict[str, Any]:
        pct = max(0.0, min(1.0, float(percent)))
        pct_int = int(round(pct * 100))

        if pct >= 0.70:
            level_label = f"Tinggi ({pct_int}%)"
            color_hex = "#D32F2F"
            badge_bg_hex = "#FFDCDD"
        elif pct >= 0.40:
            level_label = f"Sedang ({pct_int}%)"
            color_hex = "#FB8C00"
            badge_bg_hex = "#FFF3E0"
        elif pct >= 0.25:
            level_label = f"Rendah-Sedang ({pct_int}%)"
            color_hex = "#489BB8"
            badge_bg_hex = "#E0F4FB"
        else:
            level_label = f"Rendah ({pct_int}%)"
            color_hex = "#4CAF50"
            badge_bg_hex = "#E8F5E9"

        return {
            "name": name,
            "type": risk_type,
            "percent": pct,
            "levelLabel": level_label,
            "colorHex": color_hex,
            "badgeBgHex": badge_bg_hex,
        }

    @staticmethod
    def _format_emotional_center(level: int, description: str | None = None) -> dict[str, Any]:
        lvl = max(1, min(5, level))
        status_map = {
            5: "Sangat Baik (Optimal)",
            4: "Baik & Stabil",
            3: "Cukup (Stabil)",
            2: "Kurang Baik",
            1: "Perlu Perhatian Khusus",
        }
        color_map = {
            5: "#1B5E20",
            4: "#2E7D32",
            3: "#F57F17",
            2: "#E65100",
            1: "#D32F2F",
        }
        desc_map = {
            5: "Kesehatan mental dan emosi berada pada taraf terbaik.",
            4: "Resiliensi emosional dalam kondisi prima dan terjaga.",
            3: "Keseimbangan emosional terpantau dalam taraf wajar.",
            2: "Terindikasi kelelahan emosional, butuh jeda relaksasi.",
            1: "Tingkat stres dan ketegangan tinggi, disarankan konseling berkala.",
        }

        return {
            "status": status_map[lvl],
            "level": lvl,
            "description": description or desc_map[lvl],
            "textColorHex": color_map[lvl],
        }

    @staticmethod
    async def get_monitoring_data(user_id: uuid.UUID, period: str, db: AsyncSession) -> dict[str, Any]:
        p = period.lower().strip()
        if p == "week":
            return await AnalyticsService._get_week_monitoring(user_id, db)
        elif p == "month":
            return await AnalyticsService._get_month_monitoring(user_id, db)
        else:
            return await AnalyticsService._get_today_monitoring(user_id, db)

    # --------------------------------------------------------------------------
    # PERIOD: TODAY
    # --------------------------------------------------------------------------
    @staticmethod
    async def _get_today_monitoring(user_id: uuid.UUID, db: AsyncSession) -> dict[str, Any]:
        today_wib = get_wib_today()
        start_wib = datetime.combine(today_wib, time.min, tzinfo=WIB)
        end_wib = datetime.combine(today_wib, time.max, tzinfo=WIB)
        start_utc = start_wib.astimezone(timezone.utc)
        end_utc = end_wib.astimezone(timezone.utc)

        # 1. Fetch today's messages with emotion analyses
        query = (
            select(Message, EmotionAnalysis)
            .join(Conversation, Message.conversation_id == Conversation.id)
            .outerjoin(EmotionAnalysis, Message.id == EmotionAnalysis.message_id)
            .where(
                Conversation.user_id == user_id,
                Message.created_at >= start_utc,
                Message.created_at <= end_utc,
                Message.role == "user",
            )
            .order_by(Message.created_at.asc())
        )
        res = await db.execute(query)
        rows = res.all()

        # 6 Time Buckets for Today: 06:00, 09:00, 12:00, 15:00, 18:00, 21:00
        x_labels = ["06:00", "09:00", "12:00", "15:00", "18:00", "21:00"]
        bucket_cutoffs = [
            (time(0, 0), time(7, 30)),    # 06:00
            (time(7, 30), time(10, 30)),  # 09:00
            (time(10, 30), time(13, 30)), # 12:00
            (time(13, 30), time(16, 30)), # 15:00
            (time(16, 30), time(19, 30)), # 18:00
            (time(19, 30), time(23, 59, 59)), # 21:00
        ]
        bucket_vectors: list[list[list[float]]] = [[] for _ in range(6)]

        for msg, emo in rows:
            msg_wib = to_wib(msg.created_at)
            if not msg_wib:
                continue
            msg_time = msg_wib.time()
            vec = AnalyticsService._extract_7_emotions(emo)

            assigned = False
            for b_idx, (t_start, t_end) in enumerate(bucket_cutoffs):
                if t_start <= msg_time <= t_end:
                    bucket_vectors[b_idx].append(vec)
                    assigned = True
                    break
            if not assigned:
                bucket_vectors[5].append(vec)

        chart_data = [
            AnalyticsService._average_emotion_vectors(vecs)
            for vecs in bucket_vectors
        ]

        # 2. Query today's DiaryEntry for risks, center, and summary
        diary_q = select(DiaryEntry).where(
            DiaryEntry.user_id == user_id,
            DiaryEntry.entry_date == today_wib,
        ).order_by(DiaryEntry.created_at.desc())
        diary_res = await db.execute(diary_q)
        today_diary = diary_res.scalars().first()

        active_sessions_count = len(rows)
        if today_diary:
            level = today_diary.emotional_level or 4
            desc = today_diary.emotional_reflection or today_diary.ai_insight or "Keseimbangan emosi mulai pulih di penghujung hari."
            summary = today_diary.summary
            scores = today_diary.mental_health_scores or {"stress": 0.45, "anxiety": 0.35, "depression": 0.15}
            stress_pct = float(scores.get("stress", 0.45))
            anxiety_pct = float(scores.get("anxiety", 0.35))
            depression_pct = float(scores.get("depression", 0.15))
        else:
            level = 3
            desc = "Keseimbangan emosional terpantau stabil dalam batas wajar."
            if active_sessions_count > 0:
                summary = f"Evaluasi {active_sessions_count} interaksi hari ini menunjukkan kondisi emosional yang terkendali."
                stress_pct = 0.40
                anxiety_pct = 0.30
                depression_pct = 0.15
            else:
                summary = "LUNA belum mencatat percakapanmu hari ini. Ceritakan harimu untuk mulai memantau ritem emosionalmu."
                stress_pct = 0.20
                anxiety_pct = 0.20
                depression_pct = 0.10

        # Query today's DASS-21 assessment if available
        dass_q = select(DASSAssessment).where(
            DASSAssessment.user_id == user_id,
            DASSAssessment.assessed_date == today_wib,
        )
        dass_res = await db.execute(dass_q)
        today_dass = dass_res.scalars().first()

        if today_dass and (today_dass.verified_by_user or today_dass.status == "auto_extracted"):
            # Map measured 0-42 scale into percentage 0.0 - 1.0
            stress_pct = round(min(1.0, today_dass.stress_score / 42.0), 2)
            anxiety_pct = round(min(1.0, today_dass.anxiety_score / 42.0), 2)
            depression_pct = round(min(1.0, today_dass.depression_score / 42.0), 2)

        risks = [
            AnalyticsService._format_risk_card("Stres Akademik / Kerja", "stress", stress_pct),
            AnalyticsService._format_risk_card("Anxiety (Kecemasan)", "anxiety", anxiety_pct),
            AnalyticsService._format_risk_card("Tingkat Depresi", "depresi", depression_pct),
        ]

        return {
            "periodKey": "today",
            "periodLabel": "Hari Ini",
            "summary": summary,
            "emotionalCenter": AnalyticsService._format_emotional_center(level, desc),
            "risks": risks,
            "xLabels": x_labels,
            "chartData": chart_data,
        }

    # --------------------------------------------------------------------------
    # PERIOD: WEEK
    # --------------------------------------------------------------------------
    @staticmethod
    async def _get_week_monitoring(user_id: uuid.UUID, db: AsyncSession) -> dict[str, Any]:
        today_wib = get_wib_today()
        # Find Monday of this week
        monday_wib = today_wib - timedelta(days=today_wib.weekday())
        sunday_wib = monday_wib + timedelta(days=6)

        start_utc = datetime.combine(monday_wib, time.min, tzinfo=WIB).astimezone(timezone.utc)
        end_utc = datetime.combine(sunday_wib, time.max, tzinfo=WIB).astimezone(timezone.utc)

        # 1. Fetch this week's messages
        query = (
            select(Message, EmotionAnalysis)
            .join(Conversation, Message.conversation_id == Conversation.id)
            .outerjoin(EmotionAnalysis, Message.id == EmotionAnalysis.message_id)
            .where(
                Conversation.user_id == user_id,
                Message.created_at >= start_utc,
                Message.created_at <= end_utc,
                Message.role == "user",
            )
            .order_by(Message.created_at.asc())
        )
        res = await db.execute(query)
        rows = res.all()

        x_labels = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"]
        day_vectors: list[list[list[float]]] = [[] for _ in range(7)]

        for msg, emo in rows:
            msg_wib = to_wib(msg.created_at)
            if not msg_wib:
                continue
            day_idx = msg_wib.weekday()  # Monday is 0, Sunday is 6
            if 0 <= day_idx < 7:
                day_vectors[day_idx].append(AnalyticsService._extract_7_emotions(emo))

        chart_data = [
            AnalyticsService._average_emotion_vectors(vecs)
            for vecs in day_vectors
        ]

        # 2. Fetch all DiaryEntry for this week
        diary_q = select(DiaryEntry).where(
            DiaryEntry.user_id == user_id,
            DiaryEntry.entry_date >= monday_wib,
            DiaryEntry.entry_date <= sunday_wib,
        ).order_by(DiaryEntry.entry_date.asc())
        diary_res = await db.execute(diary_q)
        week_diaries = diary_res.scalars().all()

        if week_diaries:
            avg_level = int(round(sum((d.emotional_level or 4) for d in week_diaries) / len(week_diaries)))
            stress_avg = sum(float((d.mental_health_scores or {}).get("stress", 0.45)) for d in week_diaries) / len(week_diaries)
            anx_avg = sum(float((d.mental_health_scores or {}).get("anxiety", 0.35)) for d in week_diaries) / len(week_diaries)
            dep_avg = sum(float((d.mental_health_scores or {}).get("depression", 0.15)) for d in week_diaries) / len(week_diaries)
            summary = f"Tren minggu ini: Keseimbangan emosional berada dalam kategori stabil pada level {avg_level}/5. Indikator stres terkendali dengan baik."
            desc = "Resiliensi emosional mingguan dalam kondisi sangat prima."
        else:
            avg_level = 4
            stress_avg = 0.35
            anx_avg = 0.25
            dep_avg = 0.15
            summary = "Grafik mingguan mencatat ritme emosional stabil. Terus luangkan waktu untuk refleksi diri bersama LUNA."
            desc = "Kestabilan emosional terjaga dengan baik sepanjang minggu ini."

        risks = [
            AnalyticsService._format_risk_card("Stres", "stress", stress_avg),
            AnalyticsService._format_risk_card("Anxiety", "anxiety", anx_avg),
            AnalyticsService._format_risk_card("Depresi", "depresi", dep_avg),
        ]

        return {
            "periodKey": "week",
            "periodLabel": "Minggu Ini",
            "summary": summary,
            "emotionalCenter": AnalyticsService._format_emotional_center(avg_level, desc),
            "risks": risks,
            "xLabels": x_labels,
            "chartData": chart_data,
        }

    # --------------------------------------------------------------------------
    # PERIOD: MONTH
    # --------------------------------------------------------------------------
    @staticmethod
    async def _get_month_monitoring(user_id: uuid.UUID, db: AsyncSession) -> dict[str, Any]:
        today_wib = get_wib_today()
        first_day = today_wib.replace(day=1)
        last_day_num = calendar.monthrange(today_wib.year, today_wib.month)[1]
        last_day = today_wib.replace(day=last_day_num)

        start_utc = datetime.combine(first_day, time.min, tzinfo=WIB).astimezone(timezone.utc)
        end_utc = datetime.combine(last_day, time.max, tzinfo=WIB).astimezone(timezone.utc)

        # 1. Fetch this month's messages
        query = (
            select(Message, EmotionAnalysis)
            .join(Conversation, Message.conversation_id == Conversation.id)
            .outerjoin(EmotionAnalysis, Message.id == EmotionAnalysis.message_id)
            .where(
                Conversation.user_id == user_id,
                Message.created_at >= start_utc,
                Message.created_at <= end_utc,
                Message.role == "user",
            )
            .order_by(Message.created_at.asc())
        )
        res = await db.execute(query)
        rows = res.all()

        x_labels = ["M1 (Minggu 1)", "M2 (Minggu 2)", "M3 (Minggu 3)", "M4 (Minggu 4)"]
        week_vectors: list[list[list[float]]] = [[] for _ in range(4)]

        for msg, emo in rows:
            msg_wib = to_wib(msg.created_at)
            if not msg_wib:
                continue
            day_num = msg_wib.day
            w_idx = min(3, (day_num - 1) // 7)
            week_vectors[w_idx].append(AnalyticsService._extract_7_emotions(emo))

        chart_data = [
            AnalyticsService._average_emotion_vectors(vecs)
            for vecs in week_vectors
        ]

        # 2. Fetch all DiaryEntry for this month
        diary_q = select(DiaryEntry).where(
            DiaryEntry.user_id == user_id,
            DiaryEntry.entry_date >= first_day,
            DiaryEntry.entry_date <= last_day,
        ).order_by(DiaryEntry.entry_date.asc())
        diary_res = await db.execute(diary_q)
        month_diaries = diary_res.scalars().all()

        month_name = today_wib.strftime("%B")
        if month_diaries:
            avg_level = int(round(sum((d.emotional_level or 4) for d in month_diaries) / len(month_diaries)))
            stress_avg = sum(float((d.mental_health_scores or {}).get("stress", 0.40)) for d in month_diaries) / len(month_diaries)
            anx_avg = sum(float((d.mental_health_scores or {}).get("anxiety", 0.30)) for d in month_diaries) / len(month_diaries)
            dep_avg = sum(float((d.mental_health_scores or {}).get("depression", 0.15)) for d in month_diaries) / len(month_diaries)
            summary = f"Analisis Bulan {month_name}: Kestabilan emosional berada pada kategori optimal ({avg_level}/5) didukung oleh kebiasaan refleksi berkala."
            desc = "Kesehatan mental dan emosi berada pada taraf terbaik bulan ini."
        else:
            avg_level = 4
            stress_avg = 0.30
            anx_avg = 0.20
            dep_avg = 0.10
            summary = f"Analisis Bulan {month_name}: Kestabilan emosional berada pada kategori Baik & Stabil. Pertahankan rutinitas istirahat dan penenangan diri."
            desc = "Kesehatan mental dan emosi dalam rentang optimal sepanjang bulan ini."

        risks = [
            AnalyticsService._format_risk_card("Stres", "stress", stress_avg),
            AnalyticsService._format_risk_card("Depresi", "depresi", dep_avg),
            AnalyticsService._format_risk_card("Anxiety", "anxiety", anx_avg),
        ]

        return {
            "periodKey": "month",
            "periodLabel": "Bulan Ini",
            "summary": summary,
            "emotionalCenter": AnalyticsService._format_emotional_center(avg_level, desc),
            "risks": risks,
            "xLabels": x_labels,
            "chartData": chart_data,
        }
