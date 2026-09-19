from datetime import date
import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.core.tz import get_wib_today
from app.db.session import get_db_session
from app.models.coping_activity import CopingActivity, UserActivityCompletion
from app.models.dass import DASSAssessment
from app.models.diary import DiaryEntry
from app.models.enums import SafetyEventStatus
from app.models.recommendation import RecommendationItem
from app.models.safety import SafetyEvent
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


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
        raise HTTPException(status_code=404, detail="Default user not found")
    return user


@router.get("/today")
async def get_today_recommendation(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve today's tailored coping activities & condition guidance based on
    DASS-21 psychological assessment, Safety Crisis Event, and Diary Mental Health Scores.
    """
    today_wib = get_wib_today()

    # 1. Check open Crisis / Suicide Risk
    is_crisis = False
    crisis_hotline = "Kemenkes 119 ext 8 / LISA 0811-3855-472"
    crisis_guidance = (
        "Layanan konseling mandiri AI dibatasi saat terindikasi krisis emosional tinggi. "
        "Keselamatanmu adalah hal yang paling berharga. Tolong segera hubungi tenaga profesional atau orang terdekat sekarang juga."
    )

    safety_query = (
        select(SafetyEvent)
        .where(
            SafetyEvent.user_id == user.id,
            SafetyEvent.status == SafetyEventStatus.OPEN,
            SafetyEvent.severity.in_(["high", "critical"]),
        )
        .order_by(desc(SafetyEvent.detected_at))
        .limit(1)
    )
    res_safety = await db.execute(safety_query)
    open_safety_event = res_safety.scalars().first()

    # 2. Fetch today's or most recent DASS-21 assessment
    dass_query = (
        select(DASSAssessment)
        .where(DASSAssessment.user_id == user.id)
        .order_by(desc(DASSAssessment.assessed_date))
        .limit(1)
    )
    res_dass = await db.execute(dass_query)
    latest_dass = res_dass.scalars().first()

    # 3. Fetch today's or recent diary entry
    diary_query = (
        select(DiaryEntry)
        .where(DiaryEntry.user_id == user.id, DiaryEntry.entry_date == today_wib)
        .order_by(desc(DiaryEntry.created_at))
    )
    res_diary = await db.execute(diary_query)
    today_diary = res_diary.scalars().first()

    if not today_diary:
        recent_query = (
            select(DiaryEntry)
            .where(DiaryEntry.user_id == user.id)
            .order_by(desc(DiaryEntry.entry_date))
            .limit(1)
        )
        res_recent = await db.execute(recent_query)
        today_diary = res_recent.scalars().first()

    # Check for suicide / self-harm indication in DASS item 21
    suicide_dass_detected = False
    if latest_dass and latest_dass.items:
        for it in latest_dass.items:
            if it.get("item_id") == 21 and int(it.get("score", 0)) >= 2:
                suicide_dass_detected = True
                break

    if open_safety_event or suicide_dass_detected:
        is_crisis = True
        dominant_condition = "crisis"
        severity_level = "Krisis / Darurat"
        condition_label = "Protokol Krisis & Bantuan Darurat"
        condition_reason = (
            "Terdeteksi indikasi krisis emosional atau pemikiran menyakiti diri. "
            "Sesuai pedoman klinis WHO (Knowledge K013), prioritas utama saat ini adalah keselamatan dan pendampingan darurat."
        )
    else:
        # Default general
        dominant_condition = "general"
        severity_level = "Normal"
        condition_label = "Fokus: Relaksasi & Perawatan Diri"
        condition_reason = "Menjaga ritme emosi dan ketenangan pikiran harian dengan latihan mandiri sederhana."

        # Prioritas 1: Asesmen DASS-21
        if latest_dass and (latest_dass.stress_score > 0 or latest_dass.anxiety_score > 0 or latest_dass.depression_score > 0):
            s_score = latest_dass.stress_score
            a_score = latest_dass.anxiety_score
            d_score = latest_dass.depression_score

            if a_score >= s_score and a_score >= d_score and a_score >= 8:
                dominant_condition = "anxiety"
                sev = latest_dass.anxiety_severity
                if sev in ["Severe", "Extremely Severe", "Sangat Berat", "Berat"]:
                    severity_level = "Berat"
                    condition_label = "Kecemasan Berat: Grounding Somatis"
                    condition_reason = (
                        "Terdeteksi kecemasan tinggi atau overthinking intens. "
                        "Teknik Grounding somatis menstabilkan respon panik (Knowledge K002)."
                    )
                elif sev in ["Moderate", "Sedang"]:
                    severity_level = "Sedang"
                    condition_label = "Kecemasan Sedang: Notice & Name"
                    condition_reason = (
                        "Terdeteksi kecemasan sedang & overthinking. "
                        "Metode 'Notice and Name' terbukti membantu melepaskan diri dari pikiran menjebak (Knowledge K003)."
                    )
                else:
                    severity_level = "Ringan"
                    condition_label = "Kecemasan Ringan: Stabilisasi Napas"
                    condition_reason = (
                        "Terindikasi ketegangan cemas ringan. "
                        "Latihan pernapasan lambat teratur membantu memperlambat respon fisiologis cemas (Knowledge K009)."
                    )

            elif s_score >= d_score and s_score >= 15:
                dominant_condition = "stress"
                sev = latest_dass.stress_severity
                if sev in ["Severe", "Extremely Severe", "Sangat Berat", "Berat"]:
                    severity_level = "Berat"
                    condition_label = "Stres Berat: Grounding Badai Emosi"
                    condition_reason = (
                        "Terdeteksi badai emosional dan stres tingkat berat. "
                        "Teknik Grounding intensif membantu menstabilkan diri dari pikiran yang membebani (Knowledge K002)."
                    )
                elif sev in ["Moderate", "Sedang"]:
                    severity_level = "Sedang"
                    condition_label = "Stres Sedang: PMR & Solusi Bertahap"
                    condition_reason = (
                        "Terdeteksi stres tingkat sedang. "
                        "Relaksasi otot progresif (PMR) dan metode Stop-Think-Go meredakan ketegangan (Knowledge K002 & K011)."
                    )
                else:
                    severity_level = "Ringan"
                    condition_label = "Stres Ringan: Pernapasan 4-7-8"
                    condition_reason = (
                        "Terdeteksi beban stres ringan. "
                        "Latihan napas 4-7-8 dan jeda digital membantu menenangkan pikiran (Knowledge K001)."
                    )

            elif d_score >= 10:
                dominant_condition = "depression"
                sev = latest_dass.depression_severity
                if sev in ["Severe", "Extremely Severe", "Sangat Berat", "Berat"]:
                    severity_level = "Berat"
                    condition_label = "Suasana Hati Sangat Rendah: Langkah Mikro"
                    condition_reason = (
                        "Terindikasi keputusasaan atau devaluasi diri berat. "
                        "Fokuslah pada 1 langkah terkecil dan bicarakan dengan orang terdekat (Knowledge K005 & K010)."
                    )
                elif sev in ["Moderate", "Sedang"]:
                    severity_level = "Sedang"
                    condition_label = "Depresi Sedang: Aktivasi Perilaku"
                    condition_reason = (
                        "Terindikasi kelelahan emosional dan anhedonia. "
                        "Aktivasi perilaku metode tangga 'Changing My Actions' memutus siklus murung (Knowledge K010)."
                    )
                else:
                    severity_level = "Ringan"
                    condition_label = "Suasana Hati Rendah: Refleksi Syukur"
                    condition_reason = (
                        "Terindikasi suasana hati murung ringan. "
                        "Melatih rasa syukur dan pengenalan emosi membantu mengimbangi bias negatif (Knowledge K005 & K008)."
                    )

        # Prioritas 2: Jika DASS belum terisi, periksa Diary
        elif today_diary and today_diary.mental_health_scores:
            scores = today_diary.mental_health_scores
            stress = float(scores.get("stress", 0.0))
            anxiety = float(scores.get("anxiety", 0.0))
            depression = float(scores.get("depression", 0.0))

            max_score = max(stress, anxiety, depression)
            if max_score >= 0.25:
                if anxiety >= stress and anxiety >= depression:
                    dominant_condition = "anxiety"
                    severity_level = "Sedang" if anxiety >= 0.6 else "Ringan"
                    condition_label = f"Kecemasan {severity_level}: Relaksasi Napas"
                    condition_reason = "Terindikasi kecemasan dari dialog terakhir. Latihan pernapasan terbukti menenangkan saraf (Knowledge K009)."
                elif stress >= depression:
                    dominant_condition = "stress"
                    severity_level = "Sedang" if stress >= 0.6 else "Ringan"
                    condition_label = f"Stres {severity_level}: Pelepasan Beban"
                    condition_reason = "Terindikasi beban stres dari dialog terakhir. Teknik relaksasi membantu mengembalikan ketenangan (Knowledge K001)."
                else:
                    dominant_condition = "depression"
                    severity_level = "Sedang" if depression >= 0.6 else "Ringan"
                    condition_label = f"Pemulihan Energi {severity_level}: Aktivasi"
                    condition_reason = "Terindikasi kelelahan emosional. Aktivitas ringan di luar ruangan membantu membangkitkan suasana hati (Knowledge K010)."

    # Query Coping Activities
    query_target = (
        select(CopingActivity)
        .where(
            CopingActivity.is_active.is_(True),
            CopingActivity.target_condition == dominant_condition,
        )
        .order_by(CopingActivity.created_at.asc())
    )
    res_target = await db.execute(query_target)
    target_activities = res_target.scalars().all()

    query_general = (
        select(CopingActivity)
        .where(
            CopingActivity.is_active.is_(True),
            CopingActivity.target_condition != dominant_condition,
        )
        .order_by(CopingActivity.created_at.asc())
    )
    res_general = await db.execute(query_general)
    general_activities = res_general.scalars().all()

    all_sorted_activities = list(target_activities) + list(general_activities)

    # Check user completions for today
    completion_query = select(UserActivityCompletion.activity_id).where(
        UserActivityCompletion.user_id == user.id,
        UserActivityCompletion.completed_date == today_wib,
    )
    res_comp = await db.execute(completion_query)
    completed_ids = set(res_comp.scalars().all())

    # Pick the primary activity (prefer incomplete matching activity)
    primary_activity: CopingActivity | None = None
    for act in target_activities:
        if act.id not in completed_ids:
            primary_activity = act
            break
    if not primary_activity and target_activities:
        primary_activity = target_activities[0]
    if not primary_activity and all_sorted_activities:
        primary_activity = all_sorted_activities[0]

    def _map_act(act: CopingActivity) -> dict[str, Any]:
        return {
            "id": str(act.id),
            "title": act.title,
            "category": act.category,
            "targetCondition": act.target_condition,
            "duration": act.duration,
            "difficulty": act.difficulty,
            "level": act.difficulty,
            "description": act.description,
            "instructions": act.instructions or [],
            "rationale": act.rationale or "",
            "iconName": act.icon_name or "spa",
            "isCompleted": act.id in completed_ids,
        }

    all_recommendations_mapped = [_map_act(a) for a in all_sorted_activities]

    primary_mapped = _map_act(primary_activity) if primary_activity else {
        "id": "default-1",
        "title": "Latihan Pernapasan 4-7-8",
        "category": "Mindfulness",
        "targetCondition": dominant_condition,
        "duration": "5 Menit",
        "difficulty": "Pemula",
        "level": "Pemula",
        "description": "Teknik pernapasan sederhana untuk menenangkan sistem saraf.",
        "instructions": [
            "Tarik napas dalam 4 detik.",
            "Tahan napas 7 detik.",
            "Hembuskan napas perlahan 8 detik.",
        ],
        "rationale": "Mengaktifkan saraf parasimpatik untuk meredakan ketegangan tubuh.",
        "iconName": "spa",
        "isCompleted": False,
    }

    alternatives_mapped = [
        _map_act(a)
        for a in all_sorted_activities
        if primary_activity and a.id != primary_activity.id
    ]

    return {
        "targetCondition": dominant_condition,
        "conditionLabel": condition_label,
        "conditionReason": condition_reason,
        "severityLevel": severity_level,
        "isCrisis": is_crisis,
        "crisisHotline": crisis_hotline,
        "crisisGuidance": crisis_guidance,
        "todayActivity": primary_mapped,
        "completedTodayCount": len(completed_ids),
        "alternatives": alternatives_mapped,
        "allRecommendations": all_recommendations_mapped,
    }


@router.get("")
async def get_recommendations(
    condition: str | None = Query(None, description="Filter by condition: stress, anxiety, depression, general, crisis"),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    """Get all available recommendations / coping activities sorted by condition."""
    today_wib = get_wib_today()

    query = select(CopingActivity).where(CopingActivity.is_active.is_(True))
    if condition:
        query = query.where(CopingActivity.target_condition == condition.lower().strip())
    query = query.order_by(CopingActivity.created_at.asc())

    res = await db.execute(query)
    coping_items = res.scalars().all()

    comp_query = select(UserActivityCompletion.activity_id).where(
        UserActivityCompletion.user_id == user.id,
        UserActivityCompletion.completed_date == today_wib,
    )
    res_comp = await db.execute(comp_query)
    completed_ids = set(res_comp.scalars().all())

    return [
        {
            "id": str(r.id),
            "title": r.title,
            "category": r.category,
            "targetCondition": r.target_condition,
            "duration": r.duration,
            "difficulty": r.difficulty,
            "level": r.difficulty,
            "description": r.description,
            "instructions": r.instructions or [],
            "rationale": r.rationale or "",
            "iconName": r.icon_name or "spa",
            "isCompleted": r.id in completed_ids,
        }
        for r in coping_items
    ]


@router.post("/{recommendation_id}/complete")
async def mark_recommendation_completed(
    recommendation_id: str,
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Mark a recommendation or coping activity as completed for today."""
    try:
        r_uuid = uuid.UUID(recommendation_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid recommendation ID")

    today_wib = get_wib_today()

    # 1. Check if recommendation_id matches CopingActivity
    query_act = select(CopingActivity).where(CopingActivity.id == r_uuid)
    res_act = await db.execute(query_act)
    activity = res_act.scalar_one_or_none()

    if activity:
        # Check if already completed today
        check_q = select(UserActivityCompletion).where(
            UserActivityCompletion.user_id == user.id,
            UserActivityCompletion.activity_id == activity.id,
            UserActivityCompletion.completed_date == today_wib,
        )
        res_check = await db.execute(check_q)
        existing = res_check.scalar_one_or_none()

        if not existing:
            comp = UserActivityCompletion(
                user_id=user.id,
                activity_id=activity.id,
                completed_date=today_wib,
            )
            db.add(comp)
            await db.commit()

        return {
            "message": "Activity marked as completed for today",
            "activityId": str(activity.id),
            "completedDate": str(today_wib),
            "isCompleted": True,
        }

    # 2. Check legacy RecommendationItem
    query_legacy = select(RecommendationItem).where(RecommendationItem.id == r_uuid)
    res_legacy = await db.execute(query_legacy)
    legacy_item = res_legacy.scalar_one_or_none()

    if legacy_item:
        legacy_item.is_completed = True
        await db.commit()
        return {
            "message": "Legacy recommendation marked as completed",
            "activityId": str(legacy_item.id),
            "isCompleted": True,
        }

    raise HTTPException(status_code=404, detail="Activity or recommendation item not found")
