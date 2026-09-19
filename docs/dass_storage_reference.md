# Panduan Teknis & Referensi Penyimpanan Data DASS-21 (Luna AI)

Dokumen ini adalah acuan standar bagi pengembang (termasuk modul deteksi/ekstraksi AI) untuk memahami struktur data, format penyimpanan, rumus norma psikometris, dan cara menyimpan hasil asesmen **DASS-21 (*Depression Anxiety Stress Scale 21*)** ke dalam sistem Luna AI.

---

## 1. Konsep & Filosofi Deteksi DASS-21 Non-Frontal

1. **Percakapan Alami (Non-Frontal Probing):**
   - AI tidak memberikan kuesioner kaku layaknya tes psikologi formal saat percakapan suara/teks berlangsung.
   - AI bertindak sebagai pendengar empatik. Ketika pengguna mengekspresikan tanda-tanda stres, cemas, atau suasana hati murung, AI memvalidasi perasaan dan mengajukan pertanyaan terbuka reflektif secara santai (*conversational probing*).
2. **Hybrid Auto-Filling dengan Bukti (*Evidence-Based Inference*):**
   - Dari transkrip dialog harian, AI mengekstrak butir-butir DASS-21 yang relevan.
   - Setiap butir yang terisi **wajib menyertakan kutipan kalimat pengguna** (`evidence`) sebagai dasar audit klinis, beserta tingkat keyakinan AI (`confidence`).
   - Butir yang belum pernah disinggung dalam obrolan diberi nilai default `0` (*Normal*) dengan status `unconfirmed`.
3. **Human-in-the-Loop (Koreksi Mandiri oleh Pengguna):**
   - Formulir 21 butir ini disajikan di layar **Tren Harian (*Monitoring*)**.
   - Pengguna dapat melihat transparansi penilaian AI dan berhak mengubah nilai jika merasa penilaian AI kurang akurat.

---

## 2. Pemetaan 21 Butir Instrumen Resmi DASS-21

DASS-21 terdiri dari 3 subskala masing-masing 7 butir pertanyaan. Skala penilaian menggunakan **Likert 0–3**:
- `0`: Tidak pernah / tidak berlaku sama sekali.
- `1`: Kadang-kadang / terjadi pada sebagian waktu kecil.
- `2`: Sering / sering terjadi pada sebagian besar waktu.
- `3`: Hampir selalu / terjadi secara terus-menerus.

| Item ID | Subskala | Nomor Asli | Teks Pertanyaan (Bahasa Indonesia) |
| :---: | :---: | :---: | :--- |
| **1** | Stres | S1 (Item 1) | Saya merasa sulit untuk beristirahat atau menenangkan diri |
| **2** | Kecemasan | A1 (Item 2) | Saya menyadari mulut saya terasa kering |
| **3** | Depresi | D1 (Item 3) | Saya sama sekali tidak dapat merasakan perasaan positif |
| **4** | Kecemasan | A2 (Item 4) | Saya mengalami kesulitan bernapas (misal napas cepat tanpa aktivitas fisik) |
| **5** | Depresi | D2 (Item 5) | Saya merasa sulit berinisiatif untuk melakukan sesuatu |
| **6** | Stres | S2 (Item 6) | Saya cenderung bereaksi berlebihan terhadap suatu situasi |
| **7** | Kecemasan | A3 (Item 7) | Saya mengalami gemetar (misalnya pada kedua tangan) |
| **8** | Stres | S3 (Item 8) | Saya merasa menghabiskan banyak energi karena terlalu cemas/gugup |
| **9** | Kecemasan | A4 (Item 9) | Saya khawatir terhadap situasi di mana saya mungkin panik atau mempermalukan diri |
| **10** | Depresi | D3 (Item 10) | Saya merasa tidak ada lagi hal baik yang bisa saya harapkan di masa depan |
| **11** | Stres | S4 (Item 11) | Saya mendapati diri saya mudah gelisah atau resah |
| **12** | Stres | S5 (Item 12) | Saya merasa sulit untuk rileks atau bersantai |
| **13** | Depresi | D4 (Item 13) | Saya merasa sedih, murung, dan tertekan |
| **14** | Stres | S6 (Item 14) | Saya tidak sabar menghadapi hal yang menghambat apa yang sedang saya lakukan |
| **15** | Kecemasan | A5 (Item 15) | Saya merasa hampir panik |
| **16** | Depresi | D5 (Item 16) | Saya merasa tidak mampu antusias terhadap hal apa pun |
| **17** | Depresi | D6 (Item 17) | Saya merasa bahwa diri saya tidak berharga |
| **18** | Stres | S7 (Item 18) | Saya merasa mudah tersinggung atau sensitif |
| **19** | Kecemasan | A6 (Item 19) | Saya menyadari detak jantung saya berdegup kencang tanpa alasan fisik |
| **20** | Kecemasan | A7 (Item 20) | Saya merasa takut tanpa alasan yang jelas |
| **21** | Depresi | D7 (Item 21) | Saya merasa bahwa hidup ini tidak berarti |

---

## 3. Rumus Kalkulasi & Norma Keparahan (Indonesia)

> [!IMPORTANT]
> **Aturan Pengali:**
> Karena instrumen yang digunakan adalah versi singkat 21 butir (bukan versi 42 butir penuh), maka **jumlah skor masing-masing subskala HARUS dikalikan 2** sebelum dibandingkan dengan tabel norma:
> $$\text{Skor Subskala} = \left( \sum_{i=1}^{7} \text{Skor Item Subskala} \right) \times 2$$

### Tabel Norma Cut-Off (Skor Akhir setelah dikali 2)

| Kategori Keparahan | Depresi (*Depression*) | Kecemasan (*Anxiety*) | Stres (*Stress*) |
| :--- | :---: | :---: | :---: |
| **Normal** | 0 – 9 | 0 – 7 | 0 – 14 |
| **Ringan (*Mild*)** | 10 – 13 | 8 – 9 | 15 – 18 |
| **Sedang (*Moderate*)** | 14 – 20 | 10 – 14 | 19 – 25 |
| **Berat (*Severe*)** | 21 – 27 | 15 – 19 | 26 – 33 |
| **Sangat Berat (*Extremely Severe*)** | $\ge 28$ | $\ge 20$ | $\ge 34$ |

---

## 4. Struktur Schema & Format JSON Penyimpanan

Modul AI pendeteksi DASS harus menghasilkan objek JSON dengan skema berikut:

```json
{
  "user_id": "a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11",
  "assessed_date": "2026-09-19",
  "conversation_id": "c1f7b022-54a8-4c11-9a72-10842dbbe990",
  "status": "auto_extracted",
  "verified_by_user": false,
  "subscales": {
    "depression": {
      "raw_sum": 8,
      "final_score": 16,
      "severity": "Moderate"
    },
    "anxiety": {
      "raw_sum": 6,
      "final_score": 12,
      "severity": "Moderate"
    },
    "stress": {
      "raw_sum": 10,
      "final_score": 20,
      "severity": "Moderate"
    }
  },
  "items": [
    {
      "item_id": 1,
      "scale": "stress",
      "question_text": "Saya merasa sulit untuk beristirahat atau menenangkan diri",
      "score": 2,
      "evidence": "User mengatakan: 'Dari kemarin malam kepalaku penuh dan nggak bisa tidur tenang sama sekali.'",
      "confidence": 0.88,
      "is_user_edited": false
    },
    {
      "item_id": 2,
      "scale": "anxiety",
      "question_text": "Saya menyadari mulut saya terasa kering",
      "score": 0,
      "evidence": null,
      "confidence": 0.0,
      "is_user_edited": false
    },
    {
      "item_id": 3,
      "scale": "depression",
      "question_text": "Saya sama sekali tidak dapat merasakan perasaan positif",
      "score": 2,
      "evidence": "User mengatakan: 'Semuanya hambar, hal yang biasanya bikin seneng sekarang nggak ada rasanya.'",
      "confidence": 0.84,
      "is_user_edited": false
    },
    {
      "item_id": 13,
      "scale": "depression",
      "question_text": "Saya merasa sedih, murung, dan tertekan",
      "score": 3,
      "evidence": "User menangis dan berkata: 'Aku sedih banget seharian ini, rasanya bener-bener tertekan.'",
      "confidence": 0.95,
      "is_user_edited": false
    }
  ]
}
```

---

## 5. Skema Tabel Database PostgreSQL (`dass_assessments`)

```sql
CREATE TABLE dass_assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    conversation_id UUID REFERENCES conversations(id) ON DELETE SET NULL,
    assessed_date DATE NOT NULL,
    
    -- Subscale Scores (Final Scaled Score: Raw * 2)
    depression_score INT NOT NULL DEFAULT 0,
    anxiety_score INT NOT NULL DEFAULT 0,
    stress_score INT NOT NULL DEFAULT 0,
    
    -- Severity Levels
    depression_severity VARCHAR(30) NOT NULL DEFAULT 'Normal',
    anxiety_severity VARCHAR(30) NOT NULL DEFAULT 'Normal',
    stress_severity VARCHAR(30) NOT NULL DEFAULT 'Normal',
    
    -- Status & Audit
    verified_by_user BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(30) NOT NULL DEFAULT 'auto_extracted', -- 'auto_extracted' | 'verified'
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uq_user_dass_date UNIQUE (user_id, assessed_date)
);

CREATE INDEX idx_dass_user_date ON dass_assessments (user_id, assessed_date);
```

---

## 6. Alur Integrasi REST API untuk Frontend & Worker

### Endpoint 1: Mengambil Data DASS Hari Ini
- **Method & Path:** `GET /api/v1/dass/today`
- **Headers:** `Authorization: Bearer <token>`
- **Response `200 OK`:**
  Mengembalikan objek asesmen hari ini. Jika belum ada asesmen, backend mengembalikan template default 21 butir (skor 0) agar form di mobile tetap dapat dirender untuk diisi mandiri oleh user.

### Endpoint 2: Mengupdate Hasil DASS dari Koreksi User
- **Method & Path:** `PUT /api/v1/dass/{assessment_id}`
- **Headers:** `Authorization: Bearer <token>`
- **Request Body:**
  ```json
  {
    "items": [
      {
        "item_id": 1,
        "score": 1
      },
      {
        "item_id": 3,
        "score": 2
      }
    ]
  }
  ```
- **Logika Backend:**
  1. Memperbarui nilai item yang diubah, set `is_user_edited = true`.
  2. Menghitung ulang total subskala $\times 2$.
  3. Memperbarui `depression_severity`, `anxiety_severity`, `stress_severity`.
  4. Set `verified_by_user = true` dan `status = 'verified'`.
  5. Sinkronisasi dengan kartu indikator risiko pada `AnalyticsService`.

### Endpoint 3: Ekstraksi AI Pasca Percakapan (Internal Worker / Post-Call)
- **Method & Path:** `POST /api/v1/dass/extract-today`
- **Tujuan:** Dipanggil oleh background task atau handler saat sesi panggilan/chat selesai untuk memicu ekstraksi 21 butir DASS dari riwayat obrolan hari itu.

---

## 7. Checklist Rekan Pengembang Modul DASS

- [ ] Pastikan prompt ekstraksi AI menerima transkrip harian dan memetakan kalimat ke `item_id` (1–21).
- [ ] Pastikan selalu menyertakan `evidence` (kutipan verbatim user) dan `confidence` (0.0 – 1.0).
- [ ] Jangan pernah mengalikan skor butir individual; pengali 2 hanya dikenakan pada **total per subskala**.
- [ ] Jika butir tidak terdeteksi di percakapan, berikan nilai default `score: 0`, `evidence: null`, `confidence: 0.0`.
- [ ] Gunakan fungsi kalkulasi terpusat pada `dass_service.py` untuk menghindari perbedaan acuan tabel cut-off.
