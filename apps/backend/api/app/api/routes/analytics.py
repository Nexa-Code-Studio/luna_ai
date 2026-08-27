import logging
from typing import Any

from fastapi import APIRouter, Query

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/analytics", tags=["Analytics"])


@router.get("/monitoring")
async def get_monitoring_data(period: str = Query("today")) -> dict[str, Any]:
    if period == "week":
        return {
            "periodKey": "week",
            "periodLabel": "Minggu Ini",
            "summary": "Grafik mingguan menunjukkan penurunan tingkat kecemasan sebesar 15% dibandingkan minggu lalu.",
            "emotionalCenter": {
                "status": "Baik & Stabil",
                "level": 4,
                "description": "Tingkat kesadaran emosionalmu meningkat signifikan minggu ini.",
                "textColorHex": "#2E7D32",
            },
            "risks": [
                {
                    "name": "Stres Akademik",
                    "type": "stress",
                    "percent": 0.45,
                    "levelLabel": "Sedang (45%)",
                    "colorHex": "#FB8C00",
                    "badgeBgHex": "#FFF3E0",
                }
            ],
            "xLabels": ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"],
            "chartData": [
                [0.3, 0.3, 0.2, 0.1, 0.05, 0.03, 0.02],
                [0.25, 0.35, 0.25, 0.1, 0.03, 0.01, 0.01],
                [0.2, 0.4, 0.3, 0.05, 0.03, 0.01, 0.01],
                [0.4, 0.4, 0.15, 0.03, 0.01, 0.00, 0.01],
                [0.5, 0.3, 0.15, 0.03, 0.01, 0.00, 0.01],
                [0.6, 0.3, 0.08, 0.01, 0.00, 0.00, 0.01],
                [0.55, 0.35, 0.08, 0.01, 0.00, 0.00, 0.01],
            ],
        }

    # Default 'today' period data
    return {
        "periodKey": "today",
        "periodLabel": "Hari Ini",
        "summary": "Evaluasi 3 sesi suara hari ini menunjukkan kecemasan di pagi hari yang mereda di sore hari setelah jeda istirahat.",
        "emotionalCenter": {
            "status": "Cukup (Kecenderungan Membaik)",
            "level": 3,
            "description": "Keseimbangan emosi mulai pulih di penghujung hari.",
            "textColorHex": "#F57F17",
        },
        "risks": [
            {
                "name": "Stres Akademik",
                "type": "stress",
                "percent": 0.70,
                "levelLabel": "Tinggi (70%)",
                "colorHex": "#D32F2F",
                "badgeBgHex": "#FFDCDD",
            },
            {
                "name": "Anxiety (Kecemasan)",
                "type": "anxiety",
                "percent": 0.65,
                "levelLabel": "Sedang-Tinggi (65%)",
                "colorHex": "#E57373",
                "badgeBgHex": "#FFEBEE",
            },
        ],
        "xLabels": ["06:00", "09:00", "12:00", "15:00", "18:00", "21:00"],
        "chartData": [
            [0.1, 0.2, 0.5, 0.1, 0.05, 0.03, 0.02],
            [0.05, 0.15, 0.60, 0.15, 0.03, 0.01, 0.01],
            [0.2, 0.4, 0.25, 0.1, 0.03, 0.01, 0.01],
            [0.35, 0.45, 0.15, 0.03, 0.01, 0.00, 0.01],
            [0.25, 0.35, 0.30, 0.08, 0.01, 0.00, 0.01],
            [0.30, 0.40, 0.20, 0.08, 0.01, 0.00, 0.01],
        ],
    }
