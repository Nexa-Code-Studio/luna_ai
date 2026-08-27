# Panduan Integrasi Model ML Pendeteksi Emosi (`emotion2vec_plus_large`)

> **Dokumen Panduan Pengembang ML / Model Integrator**
> 
> Dokumentasi resmi ini menjelaskan secara mendetail integrasi Model Multilingual Audio Emotion Recognition HuggingFace [`emotion2vec/emotion2vec_plus_large`](https://huggingface.co/emotion2vec/emotion2vec_plus_large) (~300M Parameters) ke dalam arsitektur backend FastAPI dan Database PostgreSQL **LUNA AI**.

---

## 1. Jawaban Pertanyaan Penyimpanan Data: Apakah Disimpan dalam JSON?

**YA, 100% DISIMPAN DALAM FORMAT JSON (PostgreSQL `JSONB`)**

- **Tabel Database**: `emotion_analyses` (Model SQLAlchemy: `EmotionAnalysis` di [`apps/backend/api/app/models/safety.py`](file:///home/mashupsoat/Project/luna_ai/apps/backend/api/app/models/safety.py)).
- **Nama Kolom**: `emotions` (bertipe `JSONB` native PostgreSQL).
- Seluruh 9 probabilitas emosi hasil dari model `emotion2vec_plus_large` disimpan secara utuh sebagai objek JSON terstruktur di kolom `emotions` tersebut.

---

## 2. Pemetaan 9 Kelas Emosi Model (`emotion2vec_plus_large`)

Model `emotion2vec_plus_large` menghasilkan 9 indeks klasifikasi resmi:

| Index | Name | Label Indonesia | Emoji | Hex Color |
| :---: | :--- | :--- | :---: | :---: |
| `0` | `angry` | Marah | 😡 | `#FF7675` |
| `1` | `disgusted` | Jijik / Muak | 🤢 | `#55EFC4` |
| `2` | `fearful` | Cemas & Takut | 😰 | `#6C63FF` |
| `3` | `happy` | Bahagia & Senang | 😃 | `#FFE6A7` |
| `4` | `neutral` | Netral & Tenang | 😌 | `#4ECDC4` |
| `5` | `other` | Lainnya | 🌫️ | `#B2BEC3` |
| `6` | `sad` | Sedih | 😢 | `#74B9FF` |
| `7` | `surprised` | Terkejut | 😲 | `#A29BFE` |
| `8` | `unknown` | Tidak Diketahui | ❓ | `#DFE6E9` |

---

## 3. Lokasi Kode & Fungsi Placeholder

- **File Service**: [`apps/backend/api/app/services/ml_emotion_detector.py`](file:///home/mashupsoat/Project/luna_ai/apps/backend/api/app/services/ml_emotion_detector.py)
- **Class Service**: `MLEmotionDetectorService`

### Fungsi Utama yang Harus Diisi (`predict_message_emotion`):

```python
@staticmethod
async def predict_message_emotion(
    text: str,
    audio_bytes: Optional[bytes] = None,
) -> dict[str, Any]:
```

### Parameter Input:
1. `text` (`str`): Teks transkrip ucapan pengguna dari Speech-To-Text (STT).
2. `audio_bytes` (`Optional[bytes]`): Raw audio bytes dari mikrofon HP pengguna (WAV/PCM 16kHz mono).

---

## 4. Format JSON Return Schema (`emotions` JSONB)

Fungsi `predict_message_emotion` **WAJIB** mengembalikan dictionary Python (JSON) berstruktur sebagai berikut:

```json
{
  "model_name": "emotion2vec_plus_large",
  "primary_emotion": "happy",
  "secondary_emotion": "neutral",
  "confidence": 0.88,
  "intensity": 0.79,
  "emotions_breakdown": [
    {
      "class_id": 3,
      "name": "happy",
      "label": "Bahagia & Senang",
      "emoji": "😃",
      "percent": 0.88,
      "color": "#FFE6A7"
    },
    {
      "class_id": 4,
      "name": "neutral",
      "label": "Netral & Tenang",
      "emoji": "😌",
      "percent": 0.06,
      "color": "#4ECDC4"
    },
    {
      "class_id": 2,
      "name": "fearful",
      "label": "Cemas & Takut",
      "emoji": "😰",
      "percent": 0.02,
      "color": "#6C63FF"
    },
    {
      "class_id": 0,
      "name": "angry",
      "label": "Marah",
      "emoji": "😡",
      "percent": 0.01,
      "color": "#FF7675"
    },
    {
      "class_id": 6,
      "name": "sad",
      "label": "Sedih",
      "emoji": "😢",
      "percent": 0.01,
      "color": "#74B9FF"
    },
    {
      "class_id": 5,
      "name": "other",
      "label": "Lainnya",
      "emoji": "🌫️",
      "percent": 0.01,
      "color": "#B2BEC3"
    },
    {
      "class_id": 7,
      "name": "surprised",
      "label": "Terkejut",
      "emoji": "😲",
      "percent": 0.01,
      "color": "#A29BFE"
    },
    {
      "class_id": 1,
      "name": "disgusted",
      "label": "Jijik / Muak",
      "emoji": "🤢",
      "percent": 0.00,
      "color": "#55EFC4"
    },
    {
      "class_id": 8,
      "name": "unknown",
      "label": "Tidak Diketahui",
      "emoji": "❓",
      "percent": 0.00,
      "color": "#DFE6E9"
    }
  ]
}
```

---

## 5. Cara Simpan Otomatis ke PostgreSQL (`save_emotion_to_db`)

Backend LUNA AI telah menyediakan helper otomatis untuk menyimpan JSON di atas ke PostgreSQL:

```python
from app.services.ml_emotion_detector import MLEmotionDetectorService

# 1. Prediksi emosi dari audio/teks
analysis_result = await MLEmotionDetectorService.predict_message_emotion(text, audio_bytes)

# 2. Simpan ke database PostgreSQL (Tabel emotion_analyses, Kolom emotions JSONB)
record = await MLEmotionDetectorService.save_emotion_to_db(
    message_id=message_id,
    analysis_result=analysis_result,
    db=db_session
)
```

---

## 6. Kalkulasi Agregasi 9 Emosi di Akhir Sesi / Diary (`aggregate_session_emotions`)

Untuk menghindari data emosi yang kaku dan mencegah hilangnya probabilitas emosi ucapan pengguna, seluruh 9 nilai emosi disimpan lengkap di kolom `JSONB emotions` per-pesan.

Di akhir sesi atau saat melihat Jurnal AI, backend menghitung **rata-rata matematis persentase 9 emosi** dari seluruh pesan pengguna menggunakan fungsi:

```python
from app.services.ml_emotion_detector import MLEmotionDetectorService

# List dari hasil emotions_breakdown per-pesan pengguna
messages_emotions = [msg1_breakdown, msg2_breakdown, msg3_breakdown]

# Menghitung persentase rata-rata kumulatif 9 emosi untuk Diary
session_emotions_breakdown = MLEmotionDetectorService.aggregate_session_emotions(messages_emotions)
```

---

## 7. Uji Coba Pengujian Backend

Jalankan pengujian backend untuk memastikan skema JSON & integrasi PostgreSQL berjalan 100%:

```bash
PYTHONPATH=. /home/mashupsoat/Project/luna_ai/.venv/bin/pytest apps/backend/api/tests/ -v
```
