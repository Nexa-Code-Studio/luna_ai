#!/usr/bin/env python3
"""
Test harness for comparing ElevenLabs v4 Turbo plain vs contextually tagged synthesis.
Uses the production ElevenLabsTTDProvider and LatencyAwareSentenceChunker.

Usage:
    python scripts/test_tts_v4_pipeline.py [--model eleven_v4_turbo] [--save]
"""

import argparse
import asyncio
import os
import sys
import time

# Ensure repository root is on PYTHONPATH
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

from packages.ai.providers.tts.elevenlabs_ttd_provider import ElevenLabsTTDProvider
from packages.ai.utils.emotion_style_mapper import strip_audio_tags
from packages.ai.utils.sentence_chunker import LatencyAwareSentenceChunker, SpeechChunk
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts
from packages.shared.config import settings


TEST_CASES = [
    {
        "name": "Case 1: Sensitive Disclosure (Plain)",
        "text": "Terima kasih sudah cerita sejauh ini. Kedengarannya beberapa minggu terakhir cukup berat.",
        "tagged": False,
    },
    {
        "name": "Case 1: Sensitive Disclosure (Tagged)",
        "text": "[warm, calm] Terima kasih sudah cerita sejauh ini. [soft, reflective] Kedengarannya beberapa minggu terakhir cukup berat.",
        "tagged": True,
    },
    {
        "name": "Case 2: Gentle Probing / Reflection (Tagged with ellipsis)",
        "text": "[gentle curiosity] Kalau boleh aku tanya... kapan terakhir kali kamu merasa benar-benar tenang?",
        "tagged": True,
    },
    {
        "name": "Case 3: Reassuring Anxiety Grounding (Tagged)",
        "text": "[calm, reassuring] Tarik napas perlahan ya. Aku ada di sini mendengarkanmu tanpa terburu-buru.",
        "tagged": True,
    },
]


async def run_harness(model_id: str, save_audio: bool = False) -> None:
    print(f"\n=======================================================")
    print(f"🎙️  ElevenLabs TTD Voice Pipeline Test Harness")
    print(f"    Model:        {model_id}")
    print(f"    Output Format: {settings.ELEVENLABS_OUTPUT_FORMAT}")
    print(f"=======================================================\n")

    provider = ElevenLabsTTDProvider(model_id=model_id)
    active_key = provider.api_key
    if not active_key or active_key.startswith("your-"):
        print("⚠️  No active ELEVENLABS_API_KEY found in environment.")
        print("    Testing text sanitization and semantic chunking locally (dry run).\n")
        dry_run = True
    else:
        print(f"🔑 Active API Key: ...{active_key[-6:] if len(active_key) >= 6 else active_key}\n")
        dry_run = False

    for idx, case in enumerate(TEST_CASES, 1):
        print(f"--- [{idx}/{len(TEST_CASES)}] {case['name']} ---")
        raw_text = case["text"]
        print(f"Raw Input:     {raw_text}")

        # 1. Test display separation
        display_text = strip_audio_tags(raw_text)
        print(f"Display Text:  {display_text}")

        # 2. Test sanitizer
        sanitized_tts = sanitize_text_for_tts(raw_text, preserve_audio_tags=True)
        print(f"Sanitized TTS: {sanitized_tts}")

        # 3. Test token stream chunking
        tokens = [t + " " for t in raw_text.split(" ")]
        async def _token_gen():
            for tok in tokens:
                yield tok

        chunker = LatencyAwareSentenceChunker()
        chunks: list[SpeechChunk] = []
        async for c in chunker.chunk_stream(_token_gen()):
            chunks.append(c)

        print(f"Semantic Chunks ({len(chunks)}):")
        for c in chunks:
            print(f"   [{c.sequence}] (first={c.is_first}, final={c.is_final})")
            print(f"       display: '{c.display_text}'")
            print(f"       tts:     '{c.tts_text}'")

        # 4. Synthesize if live keys available
        if not dry_run:
            print(f"🔊 Synthesizing over TTD WebSocket...")
            t0 = time.perf_counter()
            try:
                audio_bytes = await provider.synthesize(raw_text)
                t_elapsed = (time.perf_counter() - t0) * 1000.0
                print(f"✅ Success! Received {len(audio_bytes)} bytes in {t_elapsed:.1f}ms")

                if save_audio and audio_bytes:
                    out_filename = f"output_case_{idx}_{'tagged' if case['tagged'] else 'plain'}.mp3"
                    with open(out_filename, "wb") as f:
                        f.write(audio_bytes)
                    print(f"💾 Saved to {out_filename}")
            except Exception as e:
                print(f"❌ Synthesis error: {e}")
        print()


def main():
    parser = argparse.ArgumentParser(description="Test ElevenLabs v4 Turbo pipeline.")
    parser.add_argument(
        "--model",
        type=str,
        default=settings.TTS_MODEL or "eleven_v4_turbo",
        help="Model ID to use (default: eleven_v4_turbo)",
    )
    parser.add_argument(
        "--save",
        action="store_true",
        help="Save output audio MP3 files to current directory",
    )
    args = parser.parse_args()

    asyncio.run(run_harness(model_id=args.model, save_audio=args.save))


if __name__ == "__main__":
    main()
