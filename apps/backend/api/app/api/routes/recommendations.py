from datetime import date
import logging
from typing import Any
import uuid

from fastapi import APIRouter, Depends, Header, HTTPException, Query, status
from sqlalchemy import desc, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.security import decode_access_token
from app.core.tz import get_wib_today
from app.db.session import get_db_session
from app.models.coping_activity import CopingActivity, UserActivityCompletion
from app.models.diary import DiaryEntry
from app.models.recommendation import RecommendationItem
from app.models.user import User

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/recommendations", tags=["Recommendations"])


async def _get_current_user(
    authorization: str | None = Header(None),
    db: AsyncSession = Depends(get_db_session),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Header Authorization Bearer diperlukan",
        )

    token = authorization.split("Bearer ")[1].strip()
    decoded = decode_access_token(token)
    if not decoded or "sub" not in decoded:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token akses tidak valid atau telah kedaluwarsa",
        )

    try:
        u_uuid = uuid.UUID(decoded["sub"])
    except (ValueError, TypeError):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Format user ID dalam token tidak valid",
        )

    query_jwt = select(User).where(User.id == u_uuid)
    res_jwt = await db.execute(query_jwt)
    user = res_jwt.scalar_one_or_none()

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Pengguna tidak ditemukan atau telah dinonaktifkan",
        )

    return user


@router.get("/today")
async def get_today_recommendation(
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> dict[str, Any]:
    """Retrieve today's single tailored coping activity based on dominant psychological
    risk (stress, anxiety, depression, or general) from latest diary/emotion analysis.
    """
    today_wib = get_wib_today()

    # 1. Fetch today's diary entry for mental health scores
    diary_query = (
        select(DiaryEntry)
        .where(DiaryEntry.user_id == user.id, DiaryEntry.entry_date == today_wib)
        .order_by(desc(DiaryEntry.created_at))
    )
    res_diary = await db.execute(diary_query)
    today_diary = res_diary.scalars().first()

    # Fallback: if no diary today, check most recent diary entry
    if not today_diary:
        recent_query = (
            select(DiaryEntry)
            .where(DiaryEntry.user_id == user.id)
            .order_by(desc(DiaryEntry.entry_date))
            .limit(1)
        )
        res_recent = await db.execute(recent_query)
        today_diary = res_recent.scalars().first()

    # 2. Determine dominant condition
    dominant_condition = "general"
    condition_label = "Fokus: Relaksasi & Perawatan Diri"
    condition_reason = "Menjaga ritme emosi dan ketenangan pikiran harian"

    if today_diary and today_diary.mental_health_scores:
        scores = today_diary.mental_health_scores
        stress = float(scores.get("stress", 0.0))
        anxiety = float(scores.get("anxiety", 0.0))
        depression = float(scores.get("depression", 0.0))

        # Check threshold
        max_score = max(stress, anxiety, depression)
        if max_score >= 0.25:
            if anxiety >= stress and anxiety >= depression:
                dominant_condition = "anxiety"
                condition_label = "Fokus: Meredakan Kecemasan"
                condition_reason = "Terindikasi ketegangan emosional atau kecemasan"
            elif stress >= depression:
                dominant_condition = "stress"
                condition_label = "Fokus: Meredakan Stres"
                condition_reason = "Terindikasi beban kognitif dan stres tinggi"
            else:
                dominant_condition = "depression"
                condition_label = "Fokus: Pemulihan Energi & Mood"
                condition_reason = "Terindikasi kelelahan emosional atau suasana hati rendah"

    # 3. Query activities for dominant condition
    query_act = (
        select(CopingActivity)
        .where(
            CopingActivity.is_active.is_(True),
            CopingActivity.target_condition == dominant_condition,
        )
        .order_by(CopingActivity.created_at.asc())
    )
    res_act = await db.execute(query_act)
    target_activities = res_act.scalars().all()

    # Fallback to any active coping activity if none found for target condition
    if not target_activities:
        fallback_query = (
            select(CopingActivity)
            .where(CopingActivity.is_active.is_(True))
            .order_by(CopingActivity.created_at.asc())
        )
        res_fallback = await db.execute(fallback_query)
        target_activities = res_fallback.scalars().all()

    # 4. Check user completions for today
    completion_query = select(UserActivityCompletion.activity_id).where(
        UserActivityCompletion.user_id == user.id,
        UserActivityCompletion.completed_date == today_wib,
    )
    res_comp = await db.execute(completion_query)
    completed_ids = set(res_comp.scalars().all())

    # Pick the primary activity (prefer incomplete one, otherwise first)
    primary_activity: CopingActivity | None = None
    for act in target_activities:
        if act.id not in completed_ids:
            primary_activity = act
            break
    if not primary_activity and target_activities:
        primary_activity = target_activities[0]

    # Fallback to default dummy if database table is completely unseeded
    if not primary_activity:
        return {
            "targetCondition": dominant_condition,
            "conditionLabel": condition_label,
            "conditionReason": condition_reason,
            "todayActivity": {
                "id": "default-1",
                "title": "Latihan Pernapasan 4-7-8",
                "category": "Mindfulness",
                "targetCondition": "stress",
                "duration": "5 Menit",
                "difficulty": "Pemula",
                "description": "Teknik pernapasan sederhana untuk menenangkan sistem saraf.",
                "instructions": [
                    "Tarik napas dalam 4 detik.",
                    "Tahan napas 7 detik.",
                    "Hembuskan napas perlahan 8 detik.",
                ],
                "rationale": "Mengaktifkan saraf parasimpatik untuk meredakan ketegangan tubuh.",
                "iconName": "spa",
                "isCompleted": False,
            },
            "completedTodayCount": 0,
            "alternatives": [],
        }

    is_completed_today = primary_activity.id in completed_ids

    alternatives = [
        {
            "id": str(a.id),
            "title": a.title,
            "category": a.category,
            "targetCondition": a.target_condition,
            "duration": a.duration,
            "difficulty": a.difficulty,
            "description": a.description,
            "isCompleted": a.id in completed_ids,
        }
        for a in target_activities
        if a.id != primary_activity.id
    ]

    return {
        "targetCondition": dominant_condition,
        "conditionLabel": condition_label,
        "conditionReason": condition_reason,
        "todayActivity": {
            "id": str(primary_activity.id),
            "title": primary_activity.title,
            "category": primary_activity.category,
            "targetCondition": primary_activity.target_condition,
            "duration": primary_activity.duration,
            "difficulty": primary_activity.difficulty,
            "description": primary_activity.description,
            "instructions": primary_activity.instructions or [],
            "rationale": primary_activity.rationale or "",
            "iconName": primary_activity.icon_name or "spa",
            "isCompleted": is_completed_today,
        },
        "completedTodayCount": len(completed_ids),
        "alternatives": alternatives,
    }


@router.get("")
async def get_recommendations(
    condition: str | None = Query(None, description="Filter by condition: stress, anxiety, depression, general"),
    user: User = Depends(_get_current_user),
    db: AsyncSession = Depends(get_db_session),
) -> list[dict[str, Any]]:
    """Get all available recommendations / coping activities."""
    query = select(CopingActivity).where(CopingActivity.is_active.is_(True))
    if condition:
        query = query.where(CopingActivity.target_condition == condition.lower().strip())
    query = query.order_by(CopingActivity.created_at.asc())

    res = await db.execute(query)
    coping_items = res.scalars().all()

    if coping_items:
        today_wib = get_wib_today()
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
                "level": r.difficulty,
                "description": r.description,
                "instructions": r.instructions or [],
                "rationale": r.rationale or "",
                "isCompleted": r.id in completed_ids,
            }
            for r in coping_items
        ]

    # Legacy fallback: RecommendationItem table
    legacy_query = select(RecommendationItem)
    res_legacy = await db.execute(legacy_query)
    legacy_items = res_legacy.scalars().all()

    return [
        {
            "id": str(r.id),
            "title": r.title,
            "category": r.category,
            "targetCondition": "general",
            "duration": r.duration,
            "level": r.level,
            "description": r.description,
            "instructions": [],
            "rationale": "",
            "isCompleted": r.is_completed,
        }
        for r in legacy_items
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
