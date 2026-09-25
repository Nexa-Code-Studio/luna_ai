import asyncio
from pathlib import Path
from packages.ai.providers.tts.elevenlabs_ttd_provider import ElevenLabsTTDProvider
from packages.ai.providers.tts.edge_tts_provider import EdgeTTSProvider

OUT_DIR = Path("tests/samples_pitch")
OUT_DIR.mkdir(parents=True, exist_ok=True)

TEXT = "Aduh, maaf ya Rizky. Boleh cerita sedikit, bagian mana yang paling bikin kamu capek dari situasi ini?"

TEST_CASES = [
    ("1_jessica_natural", "cgSgspJ2msm6clMCkdW9", TEXT, "Jessica (Natural / Tanpa Tag) - Asli Playful & Warm"),
    ("2_jessica_happily", "cgSgspJ2msm6clMCkdW9", "[happily] " + TEXT, "Jessica + [happily] - Nada Ceria & Lebih Tinggi"),
    ("3_jessica_excited", "cgSgspJ2msm6clMCkdW9", "[excited] " + TEXT, "Jessica + [excited] - Nada Paling Tinggi & Antusias"),
    ("4_jessica_playful", "cgSgspJ2msm6clMCkdW9", "[playful] " + TEXT, "Jessica + [playful] - Nada Lincah & Imut"),
    ("5_jessica_softly",  "cgSgspJ2msm6clMCkdW9", "[softly] " + TEXT,  "Jessica + [softly] - Nada Lembut Berbisik"),
    ("6_laura_natural",   "FGY2WhTYpPnrIDTdsKH5", TEXT, "Laura (Natural) - Karakter Muda, Quirky & Sassy"),
    ("7_laura_happily",   "FGY2WhTYpPnrIDTdsKH5", "[happily] " + TEXT, "Laura + [happily] - Nada Muda Ceria & Tinggi"),
    ("8_bella_natural",   "hpp4J3VqNfWAUOO0d1Us", TEXT, "Bella (Natural) - Karakter Bright & Warm"),
    ("9_matilda_natural", "XrExE9yKIg1WjnnlVkGX", TEXT, "Matilda (Natural) - Karakter Upbeat & Professional"),
]

async def generate_all():
    print(f"=== Generating {len(TEST_CASES) + 1} Pitch Variations ===")
    for fname, vid, tts_text, desc in TEST_CASES:
        out_file = OUT_DIR / f"{fname}.mp3"
        print(f"Synthesizing: {desc}...")
        try:
            provider = ElevenLabsTTDProvider(voice_id=vid)
            audio = await provider.synthesize(tts_text)
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
