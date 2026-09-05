# Rules & Standard Operations Setup for Proposal LaTeX Project

Dokumen ini berisi panduan teknis, aturan penulisan, serta spesifikasi desain LaTeX untuk proposal LUNA AI pada kompetisi **HoloDev HOLOGY 9.0**.

---

## 1. Structure & Organization

Proyek LaTeX disusun secara modular sebagai berikut:

```text
docs/hology9_proposal/
├── GUIDEBOOK_HOLOGY9.md      # Ekstraksi petunjuk teknis & aturan lomba
├── LATEX_RULES.md           # Aturan penulisan & kompilasi LaTeX (dokumen ini)
├── main.tex                 # Entry point LaTeX proposal
├── references.bib           # Database referensi & sitasi biblatex/natbib
├── figures/                 # Direktori gambar, diagram, & logo
└── sections/                # Modul per bab proposal (01_title_abstract.tex, dst.)
    ├── 01_title_abstract.tex
    ├── 02_latar_belakang.tex
    ├── 03_tujuan_manfaat.tex
    ├── 04_fitur_aplikasi.tex
    ├── 05_metode_pengembangan.tex
    ├── 06_analisis_desain.tex
    ├── 07_arsitektur_sistem.tex
    ├── 08_mockup.tex
    ├── 09_rencana_implementasi.tex
    └── 10_lampiran.tex
```

---

## 2. Design System & Visual Palette (Replicating `propo-luna.pdf`)

Proposal ini mengadopsi elemen visual dari `propo-luna.pdf`:

### Palette Warna (Hex Color Tokens)
* **Primary Deep Blue (`\definecolor{PrimaryBlue}{HTML}{1E3A8A}` / `{2C3E50}`):** Digunakan untuk teks judul bab Roman (I, II, III...), header tabel utama, dan garis border utama.
* **Secondary Teal Accent (`\definecolor{TealAccent}{HTML}{14B8A6}` / `{20A090}`):** Digunakan untuk garis aksen vertikal subsection, teks sub-sub-bab, caption gambar, caption tabel, dan nomor halaman.
* **Light Lavender/Blue Shading (`\definecolor{SectionBoxBg}{HTML}{F0F4FA}` / `{EFEFFA}`):** Digunakan untuk latar belakang kotak header Bab / Section.
* **Table Header Purple (`\definecolor{TableHeaderPurple}{HTML}{594F8D}`):** Latar belakang header tabel.
* **Page Frame Border (`\definecolor{PageFrameBorder}{HTML}{D1D5DB}`):** Garis bingkai halus di sekeliling halaman.

### Typography & Layout Constraints
* **Kertas:** A4 (`210mm x 297mm`).
* **Margin:** Top 2.5cm, Bottom 2.5cm, Left 2.5cm, Right 2.5cm.
* **Header:** Line atas, `LUNA – HOLOGY 9.0` (kiri) | `HoloDev Software Development` (kanan).
* **Footer:** Nomor halaman terpusat di bawah dengan simbol diamond: `◆ \thepage ◆`.
* **Maksimal Halaman:** 30 Halaman (Sesuai aturan HOLOGY 9.0).

---

## 3. Custom Commands & Environments

### A. Section Box (`\secbox{RomanNum}{TitleText}`)
Membuat header bab berlatar belakang kotak lavender halus dengan teks biru tua dan garis aksen teal di bawahnya (persis seperti `propo-luna.pdf`).

### B. Subsection Bar (`\subsecbar{TitleText}`)
Membuat judul sub-bab dengan garis vertikal teal tebal di sebelah kiri.

### C. Sub-subsection Highlight (`\subsubsecstyle{TitleText}`)
Membuat sub-sub-bab berteks miring berwarna teal (`TealAccent`).

### D. Callout / Abstract Box (`\begin{abstractbox} ... \end{abstractbox}`)
Kotak abstrak/ringkasan dengan sudut melengkung (*rounded corners*), bayangan/garis batas lembut, dan teks rata tengah miring.

### E. Tabel Custom (`\begin{lunatable}{spec} ... \end{lunatable}`)
Tabel dengan header berwarna `TableHeaderPurple`, teks header putih tebal, dan sel yang terisolasi rapi.

---

## 4. Rules & Guidelines AI Agent

 Saat menulis/memperbarui `.tex` files:
1. **Gunakan Macro yang Sudah Ada:** Selalu gunakan `\secbox`, `\subsecbar`, `\subsubsecstyle`, dan `abstractbox` agar konsistensi desain terjaga. Jangan menulis inline styling ad-hoc secara manual.
2. **Jangan Mengubah Preamble Tanpa Uji Kompilasi:** Setiap perubahan pada `main.tex` harus langsung diuji dengan `pdflatex main.tex`.
3. **Penyusunan Bahasa:** Gunakan Bahasa Indonesia baku sesuai PUEBI/EYD, dengan istilah asing dicetak miring (*italic*).
4. **Sitasi & Referensi:** Gunakan format sitasi standar APA/IEEE `(Penulis, Tahun)` atau `\cite{...}`.
5. **Gambar & Diagram:** Masukkan gambar ke direktori `figures/`, dan selalu sertakan caption dengan macro caption miring teal `\figcaption{Judul Gambar}`.

---

## 5. Perintah Kompilasi (Build Commands)

Kompilasi proposal ke format PDF dapat dilakukan dengan menjalankan shell command:

```bash
pdflatex -interaction=nonstopmode main.tex
bibtex main
pdflatex -interaction=nonstopmode main.tex
pdflatex -interaction=nonstopmode main.tex
```

Hasil PDF akan otomatis dibuat sebagai `main.pdf`.
