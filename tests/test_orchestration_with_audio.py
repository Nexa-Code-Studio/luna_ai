import asyncio
import os
import sys
import time
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
sys.path.insert(0, str(PROJECT_ROOT / "packages"))
sys.path.insert(0, str(PROJECT_ROOT / "apps" / "backend" / "api"))

from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.services.emotion_service import EmotionService
from packages.ai.utils.emotion_style_mapper import resolve_dynamic_voice_style
from app.services.ml_emotion_detector import MLEmotionDetectorService
from shared.domain_types import EmotionDetectionResult


async def run_audio_orchestration_test():
    audio_file = "/home/mashupsoat/Project/luna_ai/tests/test_emotion/combined_speech_33s.wav"
    user_text = "Aku merasa sangat lelah dan terbebani akhir-akhir ini, semuanya terasa begitu berat."
    user_name = "Budi"

    print("=" * 80)
    print(" 🎙️ PENGUJIAN ORKESTRASI LUNA AI DENGAN FILE AUDIO NYATA")
    print(f" 📁 File Audio : {audio_file}")
    print(f" 💬 Teks User  : \"{user_text}\"")
    print("=" * 80)

    if not os.path.exists(audio_file):
        print(f"❌ File audio tidak ditemukan di: {audio_file}")
        return

    # ---------------------------------------------------------
    # TAHAP 1: Tes Model EmotionService (SER Langsung via emotion2vec_plus_large)
    # ---------------------------------------------------------
    print("\n⏳ [1/4] Menguji deteksi emosi via EmotionService (emotion2vec_plus_large)...")
    t0 = time.perf_counter()
    emo_service = EmotionService()
    emo_result: EmotionDetectionResult = emo_service.predict(audio_file)
    dur_ser = (time.perf_counter() - t0) * 1000.0

    print(f"✅ SER Selesai ({dur_ser:.1f}ms):")
    print(f"   • Primary Emotion   : {emo_result.primary_emotion.upper()} ({emo_result.confidence * 100:.1f}%)")
    print(f"   • Intensity         : {emo_result.intensity * 100:.1f}%")
    print(f"   • Secondary Emotion : {str(emo_result.secondary_emotion).upper() if emo_result.secondary_emotion else 'None'}")
    print(f"   • Model Digunakan   : {emo_result.model_used}")
    print("   • Distribusi 9 Kelas Emosi:")
    for emo, score in sorted(emo_result.scores.items(), key=lambda x: x[1], reverse=True):
        print(f"     - {emo:<12}: {score * 100:5.1f}%")

    # ---------------------------------------------------------
    # TAHAP 2: Tes MLEmotionDetectorService (Single-Pass Pipeline Service)
    # ---------------------------------------------------------
    print("\n⏳ [2/4] Menguji MLEmotionDetectorService.predict_message_emotion (Single-Pass)...")
    with open(audio_file, "rb") as f:
        audio_bytes = f.read()

    t1 = time.perf_counter()
    ml_result = await MLEmotionDetectorService.predict_message_emotion(text=user_text, audio_bytes=audio_bytes)
    dur_ml = (time.perf_counter() - t1) * 1000.0

    print(f"✅ Single-Pass ML Selesai ({dur_ml:.1f}ms):")
    print(f"   • Primary   : {ml_result['primary_emotion'].upper()} (Confidence: {ml_result['confidence'] * 100:.1f}%)")
    print(f"   • Intensity : {ml_result['intensity'] * 100:.1f}%")
    print(f"   • Secondary : {ml_result.get('secondary_emotion', 'None').upper()}")

    # ---------------------------------------------------------
    # TAHAP 3: Tes AIOrchestrator dengan Input Audio
    # ---------------------------------------------------------
    print("\n⏳ [3/4] Menjalankan AIOrchestrator.prepare_turn dengan audio_path...")
    orchestrator = AIOrchestrator()
    t2 = time.perf_counter()
    turn_res = await orchestrator.prepare_turn(
        user_text=user_text,
        audio_path=audio_file,
        user_name=user_name,
    )
    dur_orch = (time.perf_counter() - t2) * 1000.0

    print(f"✅ AIOrchestrator Selesai ({dur_orch:.1f}ms):")
    print(f"   • Status Krisis     : {turn_res.is_crisis}")
    print(f"   • Risk Level        : {turn_res.safety_decision.risk_level.upper()}")
    print(f"   • Response Policy   : {turn_res.safety_decision.response_policy}")
    print(f"   • Symptom Codes     : {[s.symptom_code for s in turn_res.symptoms.extracted_symptoms]}")
    print(f"   • Final System Prompt:")
    print("   " + "-" * 76)
    for line in turn_res.final_system_prompt.strip().split("\n")[:12]:
        print(f"   | {line}")
    print("   | ... (sisanya terpotong untuk ringkasan)")
    print("   " + "-" * 76)

    # ---------------------------------------------------------
    # TAHAP 4: Dynamic Voice Style & ElevenLabs Parameter Modulation
    # ---------------------------------------------------------
    print("\n⏳ [4/4] Menguji Resolusi Gaya Suara Dinamis (resolve_dynamic_voice_style)...")
    voice_res = resolve_dynamic_voice_style(
        mode_id="mode_2",
        detected_emotion=turn_res.emotion.primary_emotion,
        confidence=turn_res.emotion.confidence,
        intensity=turn_res.emotion.intensity,
        risk_level=turn_res.safety_decision.risk_level,
    )

    print("✅ Resolusi Suara Adaptif:")
    print(f"   • Karakter Mode     : {voice_res.mode.name} (ID: {voice_res.mode.id})")
    print(f"   • Delivery Style    : {voice_res.delivery_style.upper()}")
    print(f"   • Audio Tag         : '{voice_res.audio_tag}'")
    print(f"   • Emotion Override  : {voice_res.is_emotion_override}")
    print("   • Dynamic Voice Settings (ElevenLabs Contract):")
    for k, v in voice_res.voice_settings.items():
        print(f"     - {k:<16}: {v}")

    # ---------------------------------------------------------
    # TAHAP 5: Stream Token LLM
    # ---------------------------------------------------------
    print("\n⏳ [Bonus] Pengujian Streaming Token Respon Konseling...")
    tokens = []
    t_stream_start = time.perf_counter()
    async for tok in turn_res.token_stream:
        tokens.append(tok)
        if len(tokens) >= 15:
            break
    print(f"   • Preview Token Awal: \"{''.join(tokens)}...\"")
    print("\n" + "=" * 80)
    print(" ✨ SEMUA PENGUJIAN ORKESTRASI DENGAN FILE AUDIO NYATA BERHASIL!")
    print("=" * 80)


if __name__ == "__main__":
    asyncio.run(run_audio_orchestration_test())
