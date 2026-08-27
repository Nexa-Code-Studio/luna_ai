# 🎙️ Laporan Hasil POC: emotion2vec_plus_large

## 📌 Ringkasan Eksekutif
Pengujian **Proof of Concept (POC)** untuk deteksi emosi berbasis suara (*Speech Emotion Recognition*) menggunakan model **`iic/emotion2vec_plus_large`** telah berhasil dilaksanakan pada 5 sampel audio Bahasa Indonesia (`1.wav` sampai `5.wav`).

Model berhasil mengenali dan mengklasifikasikan emosi ke dalam 9 kategori label terstandar.

---

## 📊 Metrik Utama Pengujian

- **Total Sampel Audio**: 5 File (`1.wav` – `5.wav`)
- **Waktu Muat Model (Initial Load & Download)**: `2,754.15 detik` *(Termasuk download pertama kali file bobot `model.pt` ~1.95 GB)*
- **Rata-rata Latensi Inferensi**: `~2,322.54 ms` (sekitar 2.3 detik per sampel audio)

---

## 🎵 Hasil Analisis per File Audio

### 1. `1.wav`
- **Emosi Utama**: `surprised` (Terkejut)
- **Tingkat Kepercayaan (Confidence)**: `98.30%` (`0.9830`)
- **Latensi Inferensi**: `3,984.21 ms`
- **Breakdown Skor Emosi**:
  - `surprised` (Terkejut): 98.30%
  - `angry` (Marah): 0.93%
  - `happy` (Senang): 0.52%
  - `sad` (Sedih): 0.17%
  - `fearful` (Cemas/Takut): 0.08%
- **Raw Model Output**:
```python
[{'key': '1', 'labels': ['生气/angry', '厌恶/disgusted', '恐惧/fearful', '开心/happy', '中立/neutral', '其他/other', '难过/sad', '吃惊/surprised', '<unk>'], 'scores': [0.009295973926782608, 4.366531356936321e-05, 0.0007970388396643102, 0.0051556904800236225, 1.3840482097293716e-05, 1.1933537491515267e-09, 0.0017142313299700618, 0.9829795360565186, 8.772878534735185e-10]}]
```

---

### 2. `2.wav`
- **Emosi Utama**: `sad` (Sedih)
- **Tingkat Kepercayaan (Confidence)**: `93.23%` (`0.9323`)
- **Latensi Inferensi**: `2,117.45 ms`
- **Breakdown Skor Emosi**:
  - `sad` (Sedih): 93.23%
  - `fearful` (Cemas/Takut): 6.72%
  - `neutral` (Netral): 0.02%
  - `disgusted` (Jijik): 0.01%
- **Raw Model Output**:
```python
[{'key': '2', 'labels': ['生气/angry', '厌恶/disgusted', '恐惧/fearful', '开心/happy', '中立/neutral', '其他/other', '难过/sad', '吃惊/surprised', '<unk>'], 'scores': [1.771003007888794e-05, 8.168997010216117e-05, 0.06724530458450317, 5.172508463147096e-05, 0.00018550937238615006, 6.278679211391136e-05, 0.9322893619537354, 6.49655848974362e-05, 9.169386316898454e-07]}]
```

---

### 3. `3.wav`
- **Emosi Utama**: `neutral` (Netral)
- **Tingkat Kepercayaan (Confidence)**: `76.21%` (`0.7621`)
- **Latensi Inferensi**: `1,639.60 ms`
- **Breakdown Skor Emosi**:
  - `neutral` (Netral): 76.21%
  - `sad` (Sedih): 23.38%
  - `angry` (Marah): 0.23%
  - `surprised` (Terkejut): 0.07%
  - `happy` (Senang): 0.07%
- **Raw Model Output**:
```python
[{'key': '3', 'labels': ['生气/angry', '厌恶/disgusted', '恐惧/fearful', '开心/happy', '中立/neutral', 'other', '难过/sad', '吃惊/surprised', '<unk>'], 'scores': [0.0023017895873636007, 9.548020898364484e-05, 0.0002933449868578464, 0.0006713728071190417, 0.762147068977356, 8.013485057745129e-07, 0.23378664255142212, 0.0007034739246591926, 2.6362448335426336e-10]}]
```

---

### 4. `4.wav`
- **Emosi Utama**: `sad` (Sedih)
- **Tingkat Kepercayaan (Confidence)**: `99.99%` (`0.99997`)
- **Latensi Inferensi**: `2,418.26 ms`
- **Breakdown Skor Emosi**:
  - `sad` (Sedih): 99.99%
  - `fearful` (Cemas/Takut): 0.003%
- **Raw Model Output**:
```python
[{'key': '4', 'labels': ['生气/angry', '厌恶/disgusted', '恐惧/fearful', '开心/happy', '中立/neutral', '其他/other', '难过/sad', '吃惊/surprised', '<unk>'], 'scores': [6.389650053506557e-08, 4.4903305251864367e-07, 2.8309630579315126e-05, 1.0996275534580491e-07, 7.46512625937612e-07, 1.8881060270814487e-07, 0.9999700784683228, 4.086841443040612e-08, 4.013527843405029e-10]}]
```

---

### 5. `5.wav`
- **Emosi Utama**: `surprised` (Terkejut)
- **Tingkat Kepercayaan (Confidence)**: `100.00%` (`1.0000`)
- **Latensi Inferensi**: `1,453.18 ms`
- **Breakdown Skor Emosi**:
  - `surprised` (Terkejut): 100.00%
- **Raw Model Output**:
```python
[{'key': '5', 'labels': ['生气/angry', '厌恶/disgusted', '恐惧/fearful', '开心/happy', '中立/neutral', '其他/other', '难过/sad', '吃惊/surprised', '<unk>'], 'scores': [5.897238860436138e-12, 1.3786405827706516e-12, 3.5693070027376095e-11, 7.485121411576756e-10, 5.99863908545828e-11, 7.128922589846895e-24, 8.183575345155347e-11, 1.0, 3.823870330773543e-22]}]
```

---

## 🏁 Kesimpulan & Catatan Hasil POC

1. **Kompatibilitas Teknis**: Model `emotion2vec_plus_large` terbukti berhasil memproses audio Bahasa Indonesia dan mengembalikan probabilitas emosi terstruktur secara konsisten tanpa crash.
2. **Kategori Emosi Terdeteksi**: Dari 5 sampel audio, terdeteksi variasi emosi: **Sedih (Sad)**, **Terkejut (Surprised)**, dan **Netral (Neutral)** dengan confidence score yang sangat tinggi (>76% s/d 100%).
3. **Catatan Latensi untuk Production**:
   - Rata-rata latensi di CPU lokal adalah `~2.3 detik`.
   - Untuk skenario panggilan telepon *real-time*, latensi ini dapat dioptimalkan lebih jauh dengan menggunakan GPU (CUDA) atau mengeksekusi model di **Async Background Worker (ARQ Redis Worker)** agar tidak mengganggu aliran telepon utama.
