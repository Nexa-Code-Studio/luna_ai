import logging
import os
import tempfile
import time
from typing import Dict, Tuple

import soundfile as sf
import torch
import torchaudio

from shared.domain_types import EmotionDetectionResult



logger = logging.getLogger(__name__)

EMOTION_LABELS: Dict[int, str] = {
    0: "angry",
    1: "disgusted",
    2: "fearful",
    3: "happy",
    4: "neutral",
    5: "other",
    6: "sad",
    7: "surprised",
    8: "unknown",
}

TARGET_SAMPLE_RATE = 16000


class EmotionService:
    """
    Service Layer for Speech Emotion Recognition using `iic/emotion2vec_plus_large`.

    Note: Emotion detection results represent voice-level signals/context only
    and do NOT constitute clinical mental health diagnoses.
    """

    def __init__(self, model_name: str = "iic/emotion2vec_plus_large", hub: str = "ms"):
        self.model_name = model_name
        self.hub = hub
        self._model = None

    def load_model(self) -> None:
        """
        Lazily initializes AutoModel on first request and reuses it for subsequent calls
        within the same process.
        """
        if self._model is None:
            logger.info(f"Loading emotion model '{self.model_name}' via FunASR (hub={self.hub})...")
            from funasr import AutoModel

            self._model = AutoModel(
                model=self.model_name,
                hub=self.hub,
                disable_update=True,
            )
            logger.info(f"Emotion model '{self.model_name}' loaded successfully.")

    def _validate_and_prepare_audio(self, audio_path: str) -> Tuple[str, bool]:
        """
        Validates file existence and verifies that sample rate is 16 kHz.
        Resamples audio to 16 kHz mono WAV if the sample rate or channels differ.
        Returns (ready_audio_path, is_temporary).
        """
        if not os.path.exists(audio_path):
            raise FileNotFoundError(f"Audio file not found at: {audio_path}")

        try:
            info = sf.info(audio_path)
            sample_rate = info.samplerate
            channels = info.channels
        except Exception as e:
            logger.warning(f"Could not inspect soundfile metadata for {audio_path}: {e}")
            sample_rate = None
            channels = None

        # If already 16kHz mono WAV, return directly
        if sample_rate == TARGET_SAMPLE_RATE and channels == 1:
            return audio_path, False

        # Load audio and resample to 16kHz mono using soundfile + torchaudio Resample
        logger.info(f"Resampling audio '{audio_path}' (orig SR={sample_rate}, channels={channels}) to 16kHz mono WAV...")
        data, orig_sr = sf.read(audio_path)

        # Convert numpy array to torch tensor: shape (channels, samples)
        if data.ndim == 1:
            waveform = torch.from_numpy(data).float().unsqueeze(0)
        else:
            waveform = torch.from_numpy(data.T).float()
            waveform = torch.mean(waveform, dim=0, keepdim=True)

        if orig_sr != TARGET_SAMPLE_RATE:
            resampler = torchaudio.transforms.Resample(orig_sr, TARGET_SAMPLE_RATE)
            waveform = resampler(waveform)

        # Save resampled audio to temporary WAV file
        temp_fd, temp_wav = tempfile.mkstemp(suffix="_16k.wav")
        os.close(temp_fd)
        sf.write(temp_wav, waveform.squeeze(0).numpy(), TARGET_SAMPLE_RATE)

        return temp_wav, True


    def predict(self, audio_path: str) -> EmotionDetectionResult:
        """
        Runs speech emotion recognition on the input audio file.
        Measures pure inference latency (excluding audio preparation and model loading).
        """
        # Validate and prepare 16kHz audio input
        ready_audio_path, is_temp = self._validate_and_prepare_audio(audio_path)

        try:
            # Lazily initialize model if not loaded yet
            self.load_model()

            # Measure pure inference latency
            start_infer = time.perf_counter()
            raw_res = self._model.generate(
                input=ready_audio_path,
                granularity="utterance",
                extract_embedding=False,
            )
            latency_ms = (time.perf_counter() - start_infer) * 1000

            # Process scores
            if not raw_res or "scores" not in raw_res[0]:
                raise ValueError(f"Unexpected output format from FunASR model: {raw_res}")

            raw_scores = raw_res[0]["scores"]

            scores_dict: Dict[str, float] = {}
            best_idx = 0
            best_score = -1.0

            for idx, score_val in enumerate(raw_scores):
                label_name = EMOTION_LABELS.get(idx, f"label_{idx}")
                score_float = round(float(score_val), 4)
                scores_dict[label_name] = score_float

                if score_val > best_score:
                    best_score = score_val
                    best_idx = idx

            primary_emotion = EMOTION_LABELS.get(best_idx, "unknown")
            confidence = round(float(best_score), 4)

            return EmotionDetectionResult(
                primary_emotion=primary_emotion,
                confidence=confidence,
                scores=scores_dict,
                model_used=self.model_name,
                latency_ms=round(latency_ms, 2),
            )
        finally:
            # Clean up temporary resampled WAV file if created
            if is_temp and os.path.exists(ready_audio_path):
                try:
                    os.remove(ready_audio_path)
                except Exception as e:
                    logger.warning(f"Failed to remove temp audio file {ready_audio_path}: {e}")
