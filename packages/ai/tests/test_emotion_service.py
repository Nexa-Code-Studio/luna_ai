import os
from pathlib import Path
import pytest

# Disable tqdm monitoring thread on Windows pytest to prevent thread access violations
os.environ["TQDM_DISABLE"] = "1"

from ai.services.emotion_service import EmotionService
from shared.domain_types import EmotionDetectionResult



SAMPLE_AUDIO_1 = str(Path(__file__).resolve().parent.parent.parent.parent / "scripts" / "1.wav")
SAMPLE_AUDIO_2 = str(Path(__file__).resolve().parent.parent.parent.parent / "scripts" / "2.wav")


def test_emotion_service_predict_correctness_and_reuse():
    """
    Tests correctness of EmotionService prediction output and model reuse.
    """
    assert os.path.exists(SAMPLE_AUDIO_1), f"Sample audio not found at {SAMPLE_AUDIO_1}"
    assert os.path.exists(SAMPLE_AUDIO_2), f"Sample audio not found at {SAMPLE_AUDIO_2}"

    service = EmotionService()
    
    # 1. Model should lazily initialize on first prediction call
    assert service._model is None

    result_1 = service.predict(SAMPLE_AUDIO_1)

    # 2. Correctness checks
    assert isinstance(result_1, EmotionDetectionResult)
    assert result_1.primary_emotion in [
        "angry", "disgusted", "fearful", "happy", 
        "neutral", "other", "sad", "surprised", "unknown"
    ]
    assert 0.0 <= result_1.confidence <= 1.0
    assert isinstance(result_1.scores, dict)
    assert len(result_1.scores) == 9
    assert result_1.model_used == "iic/emotion2vec_plus_large"
    assert result_1.latency_ms > 0.0

    # 3. Model reuse check
    assert service._model is not None, "Model should be loaded after first prediction"
    model_instance_1 = service._model

    # 4. Resampling & Second prediction call (scripts/2.wav is 48kHz stereo)
    result_2 = service.predict(SAMPLE_AUDIO_2)
    assert service._model is model_instance_1, "Model instance should be reused on subsequent predictions"
    assert isinstance(result_2, EmotionDetectionResult)
    assert result_2.primary_emotion == "sad"


def test_emotion_service_file_not_found():
    """
    Tests that FileNotFoundError is raised when non-existent audio path is passed.
    """
    service = EmotionService()
    with pytest.raises(FileNotFoundError):
        service.predict("non_existent_audio.wav")
