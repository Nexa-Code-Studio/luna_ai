# PROMPT SETUP & DEPLOYMENT SERVER: LUNA AI (ELEVENLABS v4 TURBO & DEEPSEEK PROMPTING V2)

> **Instruksi Penggunaan:** Salin seluruh teks di bawah ini dan berikan langsung kepada AI Agent / DevOps Engineer yang bertugas di server target (atau jalankan secara manual langkah demi langkah).

---

```markdown
# PANDUAN EKSEKUSI SERVER: DEPLOYMENT LUNA AI v4 TURBO & PROMPTING REFINEMENT

Bertindaklah sebagai Senior Cloud & DevOps Engineer. Tugas Anda adalah melakukan pembaruan (deployment) kode Luna AI terbaru pada server produksi/staging, mengonfigurasi variabel lingkungan untuk ElevenLabs v4 Turbo dan DeepSeek System Prompt V2, melakukan build ulang kontainer `api`, serta menjalankan verifikasi kesehatan (smoke test).

---

## 1. Persiapan & Git Pull

Navigasi ke direktori root proyek Luna AI pada server:
```bash
cd /path/to/luna_ai
```

Ambil perubahan terbaru dari cabang `main`:
```bash
# Pastikan tidak ada perubahan lokal yang konflik
git status

# Ambil pembaruan terkini
git fetch origin
git pull origin main
```

---

## 2. Pembaruan Variabel Lingkungan (`.env`)

Pastikan file `.env` di server memiliki konfigurasi berikut (atau tambahkan jika belum ada):

```bash
# ==============================================================================
# LUNA AI - ELEVENLABS v4 TURBO & ORCHESTRATION CONFIGURATION
# ==============================================================================

# TTS Engine Configuration
TTS_PROVIDER=elevenlabs
TTS_MODEL=eleven_v4_turbo
TTS_ENABLE_AUDIO_TAGS=true
TTS_MODE=ttd
ELEVENLABS_TTD_URL=wss://api.elevenlabs.io/v1/text-to-dialogue/stream-input
ELEVENLABS_OUTPUT_FORMAT=mp3_44100_128
TTS_VOICE_ID=cgSgspJ2msm6clMCkdW9

# ElevenLabs Multi-Key Failover Pool (pisahkan dengan koma jika lebih dari 1)
# Sistem otomatis merotasi key berikutnya jika terjadi 401/429/kuota habis
ELEVENLABS_API_KEYS=sk_live_key1,sk_live_key2

# Feature Flags & Rollout Versioning
LUNA_PROMPT_VERSION=v2
LUNA_AUDIO_TAG_POLICY_VERSION=v2
LUNA_NORMALIZER_MODE=conversational

# LLM Direct / Gateway Configuration (DeepSeek)
LLM_PROVIDER=deepseek
DEEPSEEK_MODEL=deepseek-chat
# DEEPSEEK_API_KEY=sk-...
```

---

## 3. Rebuild Kontainer API & Zero-Downtime Restart

Lakukan build ulang image kontainer `api` tanpa mematikan database (`postgres`, `redis`, `qdrant`):

```bash
# 1. Build kontainer API dengan kode terbaru
docker compose -f docker-compose.prod.yml build api

# 2. Restart layanan API secara graceful
docker compose -f docker-compose.prod.yml up -d --no-deps api

# 3. Pantau log inisialisasi API
docker compose -f docker-compose.prod.yml logs -f --tail=50 api
```

*Pastikan log menampilkan:*
- `✅ Application startup complete.`
- `🔌 Uvicorn running on http://0.0.0.0:8888`

---

## 4. Eksekusi Verifikasi Otomatis (Sanity Smoke Test)

Jalankan suite verifikasi mandiri di dalam kontainer `luna_api` untuk memastikan kontrak WebSocket TTD v4 dan Prompting 5-layer berfungsi 100%:

```bash
docker exec luna_api python3 -c "
import unittest
loader = unittest.TestLoader()
suite = unittest.TestSuite()
suite.addTests(loader.loadTestsFromName('tests.test_ttd_contract_standalone'))
suite.addTests(loader.loadTestsFromName('tests.test_prompt_and_orchestrator_v2'))
suite.addTests(loader.loadTestsFromName('tests.test_audio_tags_and_prosody_standalone'))
suite.addTests(loader.loadTestsFromName('tests.test_matrix_regression_eval'))
runner = unittest.TextTestRunner(verbosity=2)
res = runner.run(suite)
if not res.wasSuccessful():
    print('❌ VERIFIKASI GAGAL! Periksa log kesalahan di atas.')
    exit(1)
print('✅ SEMUA 30 PENGUJIAN REGRESI LULUS DENGAN SUKSES!')
"
```

---

## 5. Prosedur Rollback Cepat (Tanpa Revert Kode)

Jika terjadi kendala kuota atau anomali pada layanan ElevenLabs upstream, Anda dapat langsung melakukan *instant rollback* ke persona legacy melalui konfigurasi lingkungan tanpa perlu mengubah kode:

1. Buka `.env` dan ubah:
   ```env
   LUNA_PROMPT_VERSION=v1
   LUNA_AUDIO_TAG_POLICY_VERSION=v1
   TTS_MODEL=eleven_v3_conversational
   ```
2. Restart kontainer `api`:
   ```bash
   docker compose -f docker-compose.prod.yml restart api
   ```
```
