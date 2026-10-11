# Luna AI — Implementation Plan: ElevenLabs v4 Turbo Contract & DeepSeek Prompting

**Basis:** `LUNA_CURRENT_STATE_ORCHESTRATION_ELEVENLABS.md` (audit 11 Oktober 2026, branch `main`, commit `a86e21c`).  
**Status:** Rencana implementasi, disetujui untuk panduan tahapan pengerjaan.  
**Scope:** Kontrak WebSocket ElevenLabs Text-to-Dialogue (TTD), pembentukan prompt DeepSeek, kendali audio tags, serta modul normalisasi/chunking yang langsung menghubungkan keduanya.  
**Out of scope:** Refaktor Flutter, STT/VAD, desain RAG baru, database, memory engine, DASS, model deteksi emosi, atau mengganti LLM/model TTS.

---

## 0. Koreksi Faktual yang Wajib Dihormati

**Jangan mengganti protokol TTD dari nol.** Audit codebase membuktikan Luna AI sudah memakai endpoint dan frame yang benar:
- Endpoint: `wss://api.elevenlabs.io/v1/text-to-dialogue/stream-input?model_id=eleven_v4_turbo&output_format=mp3_44100_128`.
- Frame pertama: `{"voices": ["<voice_id>"], "voice_settings": {"stability": ..., "similarity_boost": ...}}` dengan API key pada header `xi-api-key`.
- Frame teks: `{"inputs": [{"text": "...", "voice_id": "...", "new_turn": ...}]}`.
- Kontrol: `{"flush": true}` dan `{"close_socket": true}`.
- Parsing: `audio`, `is_final_audio_for_turn`, `is_final`, `error`.
- Penyaringan parameter v4: menghapus `style` dan `speed`.

**Fokus utama:** Kontrak dasar sudah benar, namun implementasi *semantics, boundary, reliability, prompt-to-speech coupling*, dan hasil audionya perlu diperkuat melalui unit test mocked dan benchmark terkontrol.

Rujukan resmi ElevenLabs:
- https://elevenlabs.io/docs/eleven-api/guides/how-to/websockets/realtime-tdd
- https://elevenlabs.io/docs/eleven-api/guides/how-to/websockets/tts-vs-ttd-websockets
- https://elevenlabs.io/docs/api-reference/text-to-dialogue/ttd-websocket
- https://elevenlabs.io/docs/overview/capabilities/text-to-speech/best-practices
- https://elevenlabs.io/docs/overview/capabilities/text-to-speech/eleven-v4

---

## 1. Hasil Akhir yang Diinginkan

1. Semua frame TTD mengikuti skema dan urutan lifecycle yang didokumentasikan; perbedaan `new_turn` vs boundary kalimat tidak tertukar.
2. Respons DeepSeek natural dalam Bahasa Indonesia percakapan, tidak kaku, repetitif, over-cheerful, atau ceramah panjang.
3. Audio tags opsional, tepat sasaran, ringkas, dan aman untuk konseling; tidak mengubah isi faktual atau safety response.
4. Context prompting mengutamakan ucapan pengguna *saat ini*, beberapa turn terbaru, dan maksud pertanyaan; RAG sebagai pendukung referensial tanpa mendominasi.
5. Normalisasi TTS mempertahankan gaya natural (`nggak`, `udah`, `kok`) kecuali ada alasan fonetik terbukti.
6. Chunker tidak memotong audio tag, memotong kata, atau memaksakan reset prosodi di setiap titik.
7. Semua hasil memiliki rollback/feature flags, automated offline tests, dan rekaman audio A/B terukur sebelum rollout.

---

## 2. Phase 1 — Contract Hardening ElevenLabs TTD [P0]

### 2.1 File Utama
- `packages/ai/providers/tts/elevenlabs_ttd_provider.py`
- `packages/ai/utils/emotion_style_mapper.py`
- `apps/backend/api/app/services/call_session_manager.py` (integrasi terbatas jika lifecycle wrapper mengharuskannya)
- `docs/elevenlabs_tts_prompt_pipeline.md` (sinkronisasi dokumen lama)

### 2.2 Rincian Pekerjaan
**1A — Verifikasi frame serializer dan validasi input (tanpa menulis ulang fitur benar)**:
- Pertahankan endpoint `text-to-dialogue/stream-input` dan model `eleven_v4_turbo`.
- Pastikan frame awal `voices` hanya berisi **satu** voice ID untuk `eleven_v4_turbo`.
- Pastikan API key hanya melalui header/payload koneksi yang sah dan tidak terekam dalam log.
- Kirim `voice_settings` hanya pada inisialisasi; jangan mengasumsikan perubahan per chunk didukung.
- Filter `style`, `speed`, dan semua parameter non-v4 secara eksplisit. Validasi rentang nilai parameter yang didukung (`stability`: 0.0–1.0, `similarity_boost`: 0.0–1.0).
- Jangan gunakan `try_trigger_generation`, `chunk_length_schedule`, atau legacy payload `{"text": ...}` pada TTD.

**1B — Lifecycle turn dan control frame**:
- Tandai `new_turn: true` hanya pada **boundary dialog** (chunk pertama dari giliran bicara), bukan boundary setiap kalimat dalam giliran yang sama.
- Cegah reset prosodi berulang pada sub-chunk dari respons yang sama.
- Pastikan respons pendek di bawah ambang buffer server (~40 karakter dan 8 kata) tidak tertahan sampai timeout; `flush` dikirim saat giliran selesai.
- Verifikasi penanganan `is_final_audio_for_turn` (penanda akhir audio turn) vs `is_final` (penutupan socket), termasuk antisipasi server error / timeout.
- Pastikan `close_socket` dan cleanup aman saat task dibatalkan (barge-in), jaringan putus, timeout, atau error provider.

**1C — Observability dan uji**:
- Tambahkan tracing ringkas non-PII: connection-id/turn-id, jumlah input frames, duration, bytes, `first_audio_ms`, failure reason.
- Buat mocked WebSocket test yang memverifikasi urutan frame dan lifecycle tanpa memanggil API berbayar.
- Dokumentasikan sinkronisasi kontrak pada `docs/elevenlabs_tts_prompt_pipeline.md`.

### 2.3 Acceptance Criteria
- Test init frame lulus pada satu voice; tidak ada legacy field.
- Test multiple `inputs` dalam satu respons tidak membuat `new_turn` berlaku per kalimat.
- Test respons 15–30 karakter tetap menghasilkan audio setelah finalization/flush.
- Test parser: audio base64, turn-final, session-final, error, cancel, remote disconnect.
- Tidak ada trailing buffer yang hilang atau audio digandakan.
- Tidak ada perubahan pada format event Flutter.

---

## 3. Phase 2 — DeepSeek System Prompt Refinement [P1]

### 3.1 File Utama
- `apps/backend/api/app/core/prompt_templates.py`
- `packages/ai/orchestration/orchestrator.py` (`_compose_system_prompt`, `prepare_turn`, susunan `LLMMessage`)
- `packages/ai/providers/llm/deepseek_llm.py`

### 3.2 Pemisahan Instruction Layers (Single DeepSeek Request)
- **Layer 1 (Identitas & Peran)**: Luna, pendamping kesehatan mental yang hangat, empatik, sadar batas AI, mendengarkan tanpa menghakimi.
- **Layer 2 (Prioritas Percakapan)**: Ucapan terbaru & maksud user > history relevan > ringkasan sesi > RAG referensial.
- **Layer 3 (Safety & Grounding)**: Menghormati output safety gate; krisis high/critical tetap dibypass ke SOP deterministik; DASS tetap skrining, bukan diagnosis.
- **Layer 4 (Spoken Indonesian)**: Kalimat pendek (1–3 kalimat), mudah dilafalkan, alami, tidak kaku, tanpa formula repetitif seragam ("Aku mengerti perasaanmu...").
- **Layer 5 (Voice Delivery)**: Audio tags opsional, maksimal 1 tag per segmen jika benar-benar menambah makna, prioritaskan teks dan tanda baca alami.

### 3.3 Acceptance Criteria
- Respons tidak terjebak formula template seragam.
- Sapaan santai tidak berubah menjadi ceramah konseling.
- Momen sedih: lembut dan mendengarkan.
- Momen cemas: menenangkan, konkret.
- Momen positif: hangat wajar tanpa overacting.
- Konteks turn terbaru selalu menjadi fokus respon.

---

## 4. Phase 3 — Emotion-to-Audio Tag Policy [P1]

### 4.1 File Utama
- `packages/ai/utils/emotion_style_mapper.py`
- `packages/ai/orchestration/orchestrator.py`
- `packages/ai/utils/sentence_chunker.py`

### 4.2 Kebijakan
- `emotion_style_mapper` sebagai *voice delivery hint*, bukan kewajiban mutlak bahwa semua label harus punya tag.
- Kandidat tag teruji: `[softly]`, `[thoughtful]`, `[curious]`, `[warmly]`, `[calm]`.
- Larangan keras tag teatrikal/dramatis (`[crying]`, `[screaming]`, `[laughing]`).
- Boleh tanpa tag (teks polos).
- `strip_audio_tags()` hanya melepas audio tags yang dikenali; tanda kurung biasa pengguna tidak boleh terhapus.
- Voice settings adaptif (`stability`, `similarity_boost`) dievaluasi sebelum membuka koneksi per-turn.

### 4.3 Acceptance Criteria
- Semua audio tag valid lolos parser dan bersih dari `display_text`.
- Tidak ada duplikasi tag fallback dengan output LLM.
- Emosi tidak pasti (`unknown` atau confidence rendah) tidak menyebabkan overacting.

---

## 5. Phase 4 — Sentence Chunker & Text Normalizer [P1]

### 5.1 File Utama
- `packages/ai/utils/sentence_chunker.py`
- `packages/ai/utils/tts_text_normalizer.py`

### 5.2 Rincian Pekerjaan
- Pertahankan bracket safeguard (`_is_inside_bracket`).
- Chunk berdasarkan batas prosodi aman, bukan memotong kata menggantung.
- Normalisasi minimal: membersihkan karakter pengganggu dan singkatan sulit lafal, tanpa memaksa `nggak` $\rightarrow$ `tidak` atau `udah` $\rightarrow$ `sudah` secara kaku kecuali terbukti mengganggu fonetik.
- Konsistensi antara transkrip bersih dan `tts_text` tanpa merusak makna.
- Larangan SSML `<break>` untuk model v4.

---

## 6. Phase 5 — Offline Regression, Listening Test & Rollout [P1]

### 6.1 Matriks Uji Skenario
1. Sapaan pendek (`Halo`)
2. Pengungkapan sedih (`Aku lagi capek banget, rasanya sendirian.`)
3. Pengungkapan cemas (`Aku takut presentasi besok.`)
4. Pengungkapan marah (`Aku kesel banget sama temenku.`)
5. Kabar positif (`Aku akhirnya lulus!`)
6. Percakapan berlanjut / rujukan topik sebelumnya
7. Pertanyaan konkret edukatif
8. Bahasa santai / slang
9. Ambiguitas emosi / sarkasme
10. Risiko krisis sintetis (SOP deterministik aktif)
11. Punctuation & jeda elipsis (`...`)
12. Tag audio rusak / terpotong lintas token
13. Respons 1 kalimat pendek (uji finalisasi/flush)
14. Respons multi-chunk (2–3 kalimat)

### 6.2 Evaluasi & Rollout
- A/B listening evaluation (baseline vs upgraded).
- Pengukuran metrik: TTFT, TTFA, total latency, kelancaran audio.
- Feature flags untuk rollback aman jika diperlukan: `LUNA_PROMPT_VERSION`, `LUNA_AUDIO_TAG_POLICY_VERSION`.

---

## 7. File yang Boleh Disentuh
- `packages/ai/providers/tts/elevenlabs_ttd_provider.py`
- `packages/ai/providers/llm/deepseek_llm.py` (jika perlu parameter/kontrak)
- `packages/ai/orchestration/orchestrator.py`
- `apps/backend/api/app/core/prompt_templates.py`
- `packages/ai/utils/emotion_style_mapper.py`
- `packages/ai/utils/sentence_chunker.py`
- `packages/ai/utils/tts_text_normalizer.py`
- Test files di `tests/` dan `packages/ai/tests/`
- `docs/elevenlabs_tts_prompt_pipeline.md` (sinkronisasi dokumentasi)

---

## 8. Urutan Eksekusi
1. **Commit/PR A — Provider reliability**: Contract hardening + mocked protocol tests + docs kontrak.
2. **Commit/PR B — Prompt V2**: Persona delivery & context priority di `_compose_system_prompt`, `LUNA_SYSTEM_PROMPT`.
3. **Commit/PR C — Tag policy**: `emotion_style_mapper`, validasi tag, fallback policy.
4. **Commit/PR D — Prosody/norm**: Threshold chunking + normalisasi informal.
5. **Commit/PR E — A/B evaluation & rollout**: Hasil uji, verifikasi metrik.
