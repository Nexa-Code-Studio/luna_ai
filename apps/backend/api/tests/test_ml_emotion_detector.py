import os
from pathlib import Path
import pytest
from app.services.ml_emotion_detector import MLEmotionDetectorService

# Paths to sample WAV audio files
PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent.parent.parent
SAMPLE_AUDIO_1 = str(PROJECT_ROOT / "tests" / "test_emotion" / "1.wav")
SAMPLE_AUDIO_2 = str(PROJECT_ROOT / "tests" / "test_emotion" / "2.wav")


@pytest.mark.asyncio
async def test_dynamic_text_emotion_happy():
    text = "Saya sangat bersyukur, senang, dan bahagia sekali hari ini!"
    res = await MLEmotionDetectorService.predict_message_emotion(text=text, audio_bytes=None)

    assert res["model_name"] == "emotion2vec_plus_large (dynamic-text)"
    assert res["primary_emotion"] == "happy"
    assert res["confidence"] > 0.40
    assert len(res["emotions_breakdown"]) == 9

    # Breakdown top item should be happy
    assert res["emotions_breakdown"][0]["name"] == "happy"
    assert res["emotions_breakdown"][0]["percent"] > 0.40

    # Ensure dynamic percentage, not hardcoded 0.60
    total_pct = sum(item["percent"] for item in res["emotions_breakdown"])
    assert 0.95 <= total_pct <= 1.05


@pytest.mark.asyncio
async def test_dynamic_text_emotion_fearful():
    text = "Aku cemas dan takut banget, panik, stres dan gelisah sekali."
    res = await MLEmotionDetectorService.predict_message_emotion(text=text, audio_bytes=None)

    assert res["model_name"] == "emotion2vec_plus_large (dynamic-text)"
    assert res["primary_emotion"] == "fearful"
    assert res["confidence"] > 0.40
    assert res["emotions_breakdown"][0]["name"] == "fearful"


@pytest.mark.asyncio
async def test_dynamic_text_emotion_sad():
    text = "Aku sangat sedih, kecewa, lelah, dan menangis terus."
    res = await MLEmotionDetectorService.predict_message_emotion(text=text, audio_bytes=None)

    assert res["model_name"] == "emotion2vec_plus_large (dynamic-text)"
    assert res["primary_emotion"] == "sad"
    assert res["confidence"] > 0.40
    assert res["emotions_breakdown"][0]["name"] == "sad"


@pytest.mark.asyncio
async def test_dynamic_text_emotion_neutral():
    text = "Saya ingin menanyakan informasi jadwal sesi besok."
    res = await MLEmotionDetectorService.predict_message_emotion(text=text, audio_bytes=None)

    assert res["model_name"] == "emotion2vec_plus_large (dynamic-text)"
    assert res["primary_emotion"] == "neutral"


@pytest.mark.asyncio
async def test_audio_emotion_with_real_wav_bytes():
    assert os.path.exists(SAMPLE_AUDIO_1), f"Sample audio 1 not found: {SAMPLE_AUDIO_1}"

    with open(SAMPLE_AUDIO_1, "rb") as f:
        audio_bytes = f.read()

    res = await MLEmotionDetectorService.predict_message_emotion(
        text="Contoh teks",
        audio_bytes=audio_bytes,
    )

    assert res["model_name"] == "emotion2vec_plus_large"
    assert res["primary_emotion"] in [
        "angry", "disgusted", "fearful", "happy", "neutral", "other", "sad", "surprised", "unknown"
    ]
    assert 0.0 <= res["confidence"] <= 1.0
    assert len(res["emotions_breakdown"]) == 9
    assert "latency_ms" in res
    assert res["latency_ms"] > 0


def test_aggregate_session_emotions():
    sample_turn_1 = [
        {"class_id": 3, "name": "happy", "label": "Bahagia & Senang", "emoji": "😃", "percent": 0.70, "color": "#FFE6A7"},
        {"class_id": 4, "name": "neutral", "label": "Netral & Tenang", "emoji": "😌", "percent": 0.20, "color": "#4ECDC4"},
        {"class_id": 2, "name": "fearful", "label": "Cemas & Takut", "emoji": "😰", "percent": 0.10, "color": "#6C63FF"},
    ]
    sample_turn_2 = [
        {"class_id": 3, "name": "happy", "label": "Bahagia & Senang", "emoji": "😃", "percent": 0.50, "color": "#FFE6A7"},
        {"class_id": 4, "name": "neutral", "label": "Netral & Tenang", "emoji": "😌", "percent": 0.40, "color": "#4ECDC4"},
        {"class_id": 2, "name": "fearful", "label": "Cemas & Takut", "emoji": "😰", "percent": 0.10, "color": "#6C63FF"},
    ]

    aggregated = MLEmotionDetectorService.aggregate_session_emotions([sample_turn_1, sample_turn_2])

    assert len(aggregated) > 0
    # Happy average should be (0.70 + 0.50) / 2 = 0.60
    happy_item = next(item for item in aggregated if item["name"] == "happy")
    assert happy_item["percent"] == 0.60

    # Neutral average should be (0.20 + 0.40) / 2 = 0.30
    neutral_item = next(item for item in aggregated if item["name"] == "neutral")
    assert neutral_item["percent"] == 0.30
