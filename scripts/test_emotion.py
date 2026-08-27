import os
import sys
import time
from pathlib import Path

def run_poc(audio_paths: list[str]):
    existing_paths = [p for p in audio_paths if os.path.exists(p)]
    if not existing_paths:
        print(f"❌ Error: Tidak ada file audio yang ditemukan di path: {audio_paths}")
        print("Silakan letakkan file audio WAV (misal: scripts/1.wav ... scripts/5.wav) lalu jalankan kembali script ini.")
        return

    print("==================================================")
    print(" 🎙️ POC Speech Emotion Recognition (emotion2vec_plus_large)")
    print("==================================================")
    print(f"File Audio ditemukan ({len(existing_paths)}): {[os.path.basename(p) for p in existing_paths]}")
    print("Loading model 'iic/emotion2vec_plus_large' via FunASR...")

    try:
        from funasr import AutoModel
    except ImportError:
        print("\n❌ Error: Library 'funasr' belum ter-install di environment.")
        print("Silakan install dependensi terlebih dahulu dengan:")
        print("pip install funasr modelscope torch torchaudio soundfile")
        return

    # Load model 1x saja
    start_load = time.perf_counter()
    model = AutoModel(
        model="iic/emotion2vec_plus_large",
        hub="ms",
        disable_update=True
    )
    load_duration = time.perf_counter() - start_load
    print(f"✅ Model loaded successfully in {load_duration:.2f} seconds.\n")

    results = []

    for idx, audio_path in enumerate(existing_paths, 1):
        filename = os.path.basename(audio_path)
        print(f"--------------------------------------------------")
        print(f" ⏳ [{idx}/{len(existing_paths)}] Testing: {filename}")
        print(f"--------------------------------------------------")

        start_infer = time.perf_counter()
        res = model.generate(
            input=audio_path,
            granularity="utterance",
            extract_embedding=False
        )
        latency_ms = (time.perf_counter() - start_infer) * 1000

        print(f"📄 RAW OUTPUT ({filename}):")
        print(res)
        print(f"⏱️ Inference Latency: {latency_ms:.2f} ms\n")

        results.append({
            "filename": filename,
            "path": audio_path,
            "raw_output": res,
            "latency_ms": latency_ms
        })

    # Output ke poc_result.md sesuai instruksi Ekya
    output_md_path = Path(__file__).parent / "poc_result.md"
    with open(output_md_path, "w", encoding="utf-8") as f:
        f.write("# 🎙️ POC Result: emotion2vec_plus_large\n\n")
        f.write(f"- **Total Audio Files Tested**: `{len(results)}`\n")
        f.write(f"- **Model Load Time**: `{load_duration:.2f} s`\n\n")
        
        for item in results:
            f.write(f"### 🎵 File: `{item['filename']}`\n")
            f.write(f"- **Inference Latency**: `{item['latency_ms']:.2f} ms`\n")
            f.write("#### 📄 Raw Model Output\n```python\n")
            f.write(str(item['raw_output']))
            f.write("\n```\n\n")

    print("==================================================")
    print(f"✅ Semua pengujian selesai ({len(results)} file)!")
    print(f"📝 Hasil POC telah ditulis ke: {output_md_path}")
    print("==================================================")

if __name__ == "__main__":
    script_dir = Path(__file__).parent
    
    # Jika ada argumen command line, gunakan argumen tersebut
    if len(sys.argv) > 1:
        audio_files = sys.argv[1:]
    else:
        # Default: cari 1.wav sampai 5.wav di folder scripts
        default_files = [str(script_dir / f"{i}.wav") for i in range(1, 6)]
        audio_files = [f for f in default_files if os.path.exists(f)]
        if not audio_files:
            audio_files = [str(script_dir / "1.wav")]

    run_poc(audio_files)

