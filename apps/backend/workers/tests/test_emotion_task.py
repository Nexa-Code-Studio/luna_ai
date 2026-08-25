import json
import os
from pathlib import Path
import pytest

# Disable tqdm monitoring thread on Windows pytest to prevent thread access violations
os.environ["TQDM_DISABLE"] = "1"

from app.tasks.emotion_task import detect_voice_emotion_task

SAMPLE_AUDIO = str(Path(__file__).resolve().parent.parent.parent.parent.parent / "scripts" / "1.wav")


@pytest.mark.asyncio
async def test_detect_voice_emotion_task_success():
    """
    Integration test verifying detect_voice_emotion_task executes EmotionService,
    returns valid serializable dictionary, and preserves emotion metadata.
    """
    assert os.path.exists(SAMPLE_AUDIO), f"Sample audio file not found at {SAMPLE_AUDIO}"

    res = await detect_voice_emotion_task(
        ctx={},
        audio_path=SAMPLE_AUDIO,
        conversation_id="conv_123",
        message_id="msg_456",
    )

    assert res["status"] == "completed"
    assert res["audio_path"] == SAMPLE_AUDIO
    assert res["conversation_id"] == "conv_123"
    assert res["message_id"] == "msg_456"

    emotion_result = res["emotion_result"]
    assert isinstance(emotion_result, dict)
    assert emotion_result["primary_emotion"] in [
        "angry", "disgusted", "fearful", "happy",
        "neutral", "other", "sad", "surprised", "unknown"
    ]
    assert 0.0 <= emotion_result["confidence"] <= 1.0
    assert isinstance(emotion_result["scores"], dict)
    assert len(emotion_result["scores"]) == 9
    assert emotion_result["model_used"] == "iic/emotion2vec_plus_large"
    assert emotion_result["latency_ms"] > 0.0

    # Ensure return dictionary is 100% JSON serializable for ARQ Redis worker
    serialized = json.dumps(res)
    assert isinstance(serialized, str)


@pytest.mark.asyncio
async def test_detect_voice_emotion_task_file_not_found():
    """
    Verifies FileNotFoundError is raised when non-existent audio file is passed.
    """
    with pytest.raises(FileNotFoundError):
        await detect_voice_emotion_task({}, "non_existent_audio.wav")
