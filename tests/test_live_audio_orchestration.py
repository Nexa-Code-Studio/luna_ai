import asyncio
import os
import sys
import time
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))
sys.path.insert(0, str(PROJECT_ROOT / "packages"))
sys.path.insert(0, str(PROJECT_ROOT / "apps" / "backend" / "api"))

from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.providers.tts.elevenlabs_ttd_provider import ElevenLabsTTDProvider
from packages.ai.utils.emotion_style_mapper import (
    get_voice_settings_for_style,
    map_emotion_to_delivery_style,
    strip_audio_tags,
)
from packages.ai.utils.sentence_chunker import (
    LatencyAwareSentenceChunker,
    SpeechChunk,
)
from packages.shared.config import settings


async def run_live_audio_test(
    audio_path: str = "tests/test_emotion/1.wav",
    user_transcript: str = "Kan aku udah bilang berkali-kali, tapi kamu masih melakukan hal yang sama.",
    output_audio_path: str = "tests/output_1_luna_response.mp3",
    user_name: str | None = "Rizky",
):
    print("=" * 70)
    print(" 🎙️ LUNA ORCHESTRATION & ELEVENLABS v3 TTD TEST WITH LIVE AUDIO")
    print("=" * 70)
    print(f"📁 Input Audio File : {audio_path}")
    print(f"💬 User Speech Text : \"{user_transcript}\"")
    print(f"👤 User Name        : {user_name}")
    print(f"🎯 Output MP3 Target: {output_audio_path}\n")

    if not os.path.exists(audio_path):
        raise FileNotFoundError(f"Audio file '{audio_path}' not found!")

    t0 = time.perf_counter()

    # 1. Initialize Orchestrator
    orchestrator = AIOrchestrator()

    # 2. Run Orchestrator Turn (Emotion from audio + Symptom + Risk + RAG + Prompt Formulation)
    print("⏳ [1/4] Running Orchestrator pipeline (SER + Risk + Gating + LLM preparation)...")
    turn_result = await orchestrator.prepare_turn(
        user_text=user_transcript,
        audio_path=audio_path,
        user_name=user_name,
    )

    t_orchestrator_ready = time.perf_counter()
    orch_duration_ms = (t_orchestrator_ready - t0) * 1000.0

    print(f"✅ [ORCHESTRATOR READY] in {orch_duration_ms:.1f}ms")
    print(f"   - Detected Emotion : {turn_result.emotion.primary_emotion.upper()} "
          f"(Confidence: {turn_result.emotion.confidence * 100:.1f}%, Model: {turn_result.emotion.model_used})")
    print(f"   - Risk Level       : {turn_result.safety_decision.risk_level.upper()}")
    print(f"   - RAG Retrieved    : {len(turn_result.rag_items)} items")

    # 3. Determine Delivery Style & Voice Settings
    delivery_style, audio_tag = map_emotion_to_delivery_style(
        detected_emotion=turn_result.emotion.primary_emotion,
        confidence=turn_result.emotion.confidence,
        risk_level=turn_result.safety_decision.risk_level,
    )
    voice_settings = get_voice_settings_for_style(delivery_style)
    print(f"   - Assistant Style  : {delivery_style.upper()}")
    print(f"   - Voice Settings   : {voice_settings} (Official ElevenLabs Contract)\n")

    # 4. Stream LLM tokens through LatencyAwareSentenceChunker
    print("⏳ [2/4] Connecting to ElevenLabs TTD WebSocket ('eleven_v3_conversational')...")
    tts_provider: ElevenLabsTTDProvider = ElevenLabsTTDProvider()
    ttd_session = tts_provider.create_session(voice_settings=voice_settings)
    await ttd_session.connect()
    t_ttd_connected = time.perf_counter()
    print(f"✅ [TTD CONNECTED] WebSocket handshake completed in {(t_ttd_connected - t_orchestrator_ready)*1000:.1f}ms\n")

    chunker = LatencyAwareSentenceChunker(delivery_style=delivery_style, audio_tag="")

    # Instrument LLM token stream
    llm_tokens: list[str] = []
    first_token_time: float | None = None

    async def _token_generator():
        nonlocal first_token_time
        async for token in turn_result.token_stream:
            if first_token_time is None:
                first_token_time = time.perf_counter()
                ttft_ms = (first_token_time - t0) * 1000.0
                print(f"⚡ [LLM TTFT] First token received in {ttft_ms:.1f}ms")
            llm_tokens.append(token)
            yield token

    print("⏳ [3/4] Streaming LLM tokens -> Sentence Chunker -> TTD WebSocket...")
    speech_chunks_stream = chunker.chunk_stream(_token_generator())

    generated_sentences: list[SpeechChunk] = []
    received_audio_bytes: list[bytes] = []
    first_audio_time: float | None = None

    sentence_idx = 0
    async for ref_chunk, sentence_audio in ttd_session.stream_sentence_audio(speech_chunks_stream):
        now = time.perf_counter()
        sentence_idx += 1
        if first_audio_time is None:
            first_audio_time = now
            ttfa_ms = (first_audio_time - t0) * 1000.0
            print(f"🔊 [TTFA - FIRST AUDIO READY] in {ttfa_ms:.1f}ms!")

        if ref_chunk:
            generated_sentences.append(ref_chunk)
            print(f"   📢 Sentence {sentence_idx}: \"{ref_chunk.display_text}\"")
            print(f"      TTS text   : \"{ref_chunk.tts_text}\"")
            print(f"      Audio size : {len(sentence_audio)} bytes (MP3)")
        received_audio_bytes.append(sentence_audio)

    await ttd_session.close()

    # 5. Save Audio Output
    total_audio = b"".join(received_audio_bytes)
    out_path = Path(output_audio_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_bytes(total_audio)

    t_end = time.perf_counter()
    total_time_ms = (t_end - t0) * 1000.0

    full_display_text = " ".join(c.display_text for c in generated_sentences)
    clean_history_text = strip_audio_tags(full_display_text)

    print("\n" + "=" * 70)
    print(" 🎉 HASIL AKHIR ORKESTRASI & SINTESIS SUARA LUNA")
    print("=" * 70)
    print(f"1. Transkrip Suara Input  : \"{user_transcript}\"")
    print(f"2. Emosi Terdeteksi (SER) : {turn_result.emotion.primary_emotion.upper()} ({turn_result.emotion.confidence*100:.1f}%)")
    print(f"3. Gaya Penyampaian Luna  : {delivery_style} (Audio Tag: '{audio_tag}')")
    print(f"4. Teks Respon Suara (TTS): \"{generated_sentences[0].tts_text if generated_sentences else ''}\"")
    print(f"5. Teks Tampilan UI / DB  : \"{clean_history_text}\"")
    print(f"6. File Audio Tersimpan   : {out_path.resolve()} ({len(total_audio):,} bytes)")
    print(f"7. Metrik Latensi         :")
    if first_token_time:
        print(f"   - LLM TTFT (Time To First Token) : {(first_token_time - t0)*1000:.1f} ms")
    if first_audio_time:
        print(f"   - TTFA (Time To First Audio)     : {(first_audio_time - t0)*1000:.1f} ms")
    print(f"   - Total Waktu Eksekusi           : {total_time_ms:.1f} ms")
    print("=" * 70)

    return {
        "user_transcript": user_transcript,
        "emotion": turn_result.emotion.primary_emotion,
        "confidence": turn_result.emotion.confidence,
        "delivery_style": delivery_style,
        "audio_tag": audio_tag,
        "full_display_text": clean_history_text,
        "output_audio_path": str(out_path.resolve()),
        "audio_bytes_size": len(total_audio),
        "total_time_ms": total_time_ms,
    }


if __name__ == "__main__":
    asyncio.run(run_live_audio_test())
