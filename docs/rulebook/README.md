# 📖 Luna AI Rule Book (LaTeX Project)

Project LaTeX ini berisi dokumentasi resmi **Luna AI Rule Book & Operations Manual**. Dokumen ini telah dilengkapi dengan styling modern bergaya Luna AI (Purple/Indigo theme) serta **Screenshot Placeholder Boxes** (kotak bercelah bergaris putus-putus) yang siap diisi dengan foto/tangkapan layar aplikasi saat siap.

---

## 📁 Struktur Direktori

```text
docs/rulebook/
├── main.tex                 # Berkas utama LaTeX (Cover, ToC, Chapter imports)
├── style.sty                # Package styling (Warna, Header, Callout boxes, Screenshot Macros)
├── chapters/                # Bab-bab dokumentasi
│   ├── 01_introduction.tex    # Bab 1: Pendahuluan & Visi Luna AI
│   ├── 02_user_guide.tex      # Bab 2: Panduan Antarmuka & Flow (Tempat Kotak Screenshot)
│   ├── 03_counseling_rules.tex # Bab 3: Etika & Aturan Konseling AI
│   ├── 04_safety_protocols.tex# Bab 4: Protokol Keselamatan & Risk Safety Gates
│   └── 05_troubleshooting.tex # Bab 5: Troubleshooting & FAQ
└── README.md                # Panduan kompilasi dan instruksi penggantian screenshot
```

---

## 🛠️ Cara Mengisi Screenshot

Dokumen ini memiliki **3 jenis macro** untuk placeholder screenshot:

### 1. Placeholder Berukuran Penuh (`\screenshotplaceholder`)
Digunakan untuk screenshot utama (misal: Halaman Login, Dashboard, Chat, dll).
```latex
\screenshotplaceholder[0.9\textwidth]{7cm}{Judul Tangkapan Layar}{Petunjuk tambahan atau deskripsi gambar}
```

### 2. Box Ringkas (`\screenshotbox`)
Digunakan untuk tangkapan layar modal, dialog pop-up, atau elemen ringkas.
```latex
\screenshotbox[0.85\textwidth]{4cm}{Judul Modal/Pop-up}{Deskripsi singkat}
```

### 3. Mengganti Placeholder dengan Gambar Asli (`\realscreenshot`)
Jika Anda sudah mengambil tangkapan layar asli (misal disimpan di folder `images/screenshot_login.png`), cukup ganti perintah macro di berkas chapter terkait menjadi:
```latex
\realscreenshot[0.85\textwidth]{images/screenshot_login.png}{Halaman Login Luna AI}{fig:login}
```

---

## ⚡ Cara Kompilasi PDF

### A. Menggunakan Terminal Local (pdflatex / latexmk)
Pastikan TeX Live, MacTeX, atau MiKTeX sudah terpasang pada komputer Anda:

```bash
cd docs/rulebook
pdflatex main.tex
pdflatex main.tex  # Jalankan 2x untuk memperbarui Table of Contents (Daftar Isi)
```

Atau menggunakan `latexmk`:
```bash
latexmk -pdf main.tex
```

### B. Menggunakan Overleaf
1. Compress (ZIP) seluruh isi folder `docs/rulebook/`.
2. Buka [Overleaf](https://www.overleaf.com), buat proyek baru (`New Project` -> `Upload Project`).
3. Upload berkas ZIP tersebut.
4. Pilih `main.tex` sebagai berkas utama dan klik **Recompile**.
