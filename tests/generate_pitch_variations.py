import asyncio
from pathlib import Path
from packages.ai.providers.tts.elevenlabs_ttd_provider import ElevenLabsTTDProvider
from packages.ai.providers.tts.edge_tts_provider import EdgeTTSProvider

OUT_DIR = Path("tests/samples_pitch")
OUT_DIR.mkdir(parents=True, exist_ok=True)

TEXT = "Aduh, maaf ya Rizky. Boleh cerita sedikit, bagian mana yang paling bikin kamu capek dari situasi ini?"

TEST_CASES = [
    ("1_jessica_natural", "cgSgspJ2msm6clMCkdW9", TEXT, None, "Jessica (Natural) - Asli Playful & Warm"),
    ("2_jessica_happily", "cgSgspJ2msm6clMCkdW9", TEXT, {"stability": 0.45, "similarity_boost": 0.80, "style": 0.30, "speed": 1.02}, "Jessica + VoiceSettings Ceria & Lebih Tinggi"),
    ("3_jessica_excited", "cgSgspJ2msm6clMCkdW9", TEXT, {"stability": 0.40, "similarity_boost": 0.80, "style": 0.35, "speed": 1.05}, "Jessica + VoiceSettings Excited & Antusias"),
    ("4_jessica_playful", "cgSgspJ2msm6clMCkdW9", TEXT, {"stability": 0.45, "similarity_boost": 0.80, "style": 0.25, "speed": 1.02}, "Jessica + VoiceSettings Playful & Lincah"),
    ("5_jessica_softly",  "cgSgspJ2msm6clMCkdW9", TEXT, {"stability": 0.65, "similarity_boost": 0.80, "style": 0.05, "speed": 0.92}, "Jessica + VoiceSettings Softly & Lembut"),
    ("6_laura_natural",   "FGY2WhTYpPnrIDTdsKH5", TEXT, None, "Laura (Natural) - Karakter Muda, Quirky & Sassy"),
    ("7_laura_happily",   "FGY2WhTYpPnrIDTdsKH5", TEXT, {"stability": 0.45, "similarity_boost": 0.80, "style": 0.30, "speed": 1.02}, "Laura + VoiceSettings Muda Ceria & Tinggi"),
    ("8_bella_natural",   "hpp4J3VqNfWAUOO0d1Us", TEXT, None, "Bella (Natural) - Karakter Bright & Warm"),
    ("9_matilda_natural", "XrExE9yKIg1WjnnlVkGX", TEXT, None, "Matilda (Natural) - Karakter Upbeat & Professional"),
]

async def generate_all():
    print(f"=== Generating {len(TEST_CASES) + 1} Pitch Variations ===")
    for fname, vid, tts_text, vsettings, desc in TEST_CASES:
        out_file = OUT_DIR / f"{fname}.mp3"
        print(f"Synthesizing: {desc}...")
        try:
            provider = ElevenLabsTTDProvider(voice_id=vid)
            audio = await provider.synthesize(tts_text, voice_settings=vsettings)
            out_file.write_bytes(audio)
            print(f"  -> Saved {out_file} ({len(audio):,} bytes)")
        except Exception as e:
            print(f"  -> Error: {e}")

    # EdgeTTS id-ID-GadisNeural
    print("Synthesizing: EdgeTTS id-ID-GadisNeural (Native ID High-Pitch)...")
    try:
        edge = EdgeTTSProvider()
        audio_edge = await edge.synthesize(TEXT)
        out_file_edge = OUT_DIR / "10_edgetts_gadis_neural.mp3"
        out_file_edge.write_bytes(audio_edge)
        print(f"  -> Saved {out_file_edge} ({len(audio_edge):,} bytes)")
    except Exception as e:
        print(f"  -> Error EdgeTTS: {e}")

    print("=== All Samples Generated in tests/samples_pitch/ ===")

if __name__ == "__main__":
    asyncio.run(generate_all())
