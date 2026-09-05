---
trigger: model_decision
description: Ketika aku ingin untuk mengubah, menambahkan, atau membaca proposal pada /docs
---

# Rules & Standard Operations Setup for Proposal LaTeX Project

Dokumen ini berisi panduan teknis, aturan penulisan, serta spesifikasi desain LaTeX untuk proposal LUNA AI pada kompetisi **HoloDev HOLOGY 9.0**.

---

## 1. Structure & Organization

Proyek LaTeX disusun secara modular sebagai berikut:

```text
docs/hology9_proposal/
├── GUIDEBOOK_HOLOGY9.md      # Ekstraksi petunjuk teknis & aturan lomba
├── LATEX_RULES.md           # Aturan penulisan & kompilasi LaTeX
├── main.tex                 # Entry point LaTeX proposal
├── references.bib           # Database referensi & sitasi biblatex/natbib
├── figures/                 # Direktori gambar, diagram, & logo
└── sections/                # Modul per bab proposal
    ├── 01_title_abstract.tex
    ├── 02_latar_belakang.tex
    ├── 03_tujuan_manfaat.tex
    ├── 04_fitur_aplikasi.tex
    ├── 05_metode_pengembangan.tex
    ├── 06_analisis_desain.tex
    ├── 07_arsitektur_sistem.tex
    ├── 08_mockup.tex
    ├── 09_rencana_implementasi.tex
    ├── 10_lampiran.tex
    └── 11_daftar_pustaka.tex
```

---

## 2. Design System & Visual Palette (Replicating `propo-luna.pdf`)

Proposal ini mengadopsi elemen visual presisi dari `propo-luna.pdf`:

### Palette Warna (Hex Color Tokens)
* **Primary Deep Blue (`\definecolor{PrimaryBlue}{HTML}{1E295B}`):** Digunakan untuk teks judul bab Roman (I, II, III...), header box section, dan teks penekanan utama.
* **Secondary Teal Accent (`\definecolor{TealAccent}{HTML}{20A090}`):** Digunakan untuk garis aksen vertikal subsection, teks sub-sub-bab, caption gambar, caption tabel, garis header/footer, dan nomor halaman.
* **Table Header Purple (`\definecolor{TableHeaderPurple}{HTML}{5B4B9A}`):** Latar belakang header tabel (`thead`).
* **Table Alternating Row (`\definecolor{TableAltRowBg}{HTML}{F4F1FB}`):** Latar belakang baris selang-seling (zebra striping) genap pada tabel.
* **Table Border Gray (`\definecolor{TableBorderColor}{HTML}{C4C7C5}`):** Warna abu-abu halus untuk garis kisi/border tabel (`\arrayrulecolor`).
* **Section Box Background (`\definecolor{SectionBoxBg}{HTML}{F0F2FA}`):** Latar belakang kotak header Bab / Section.
* **Page Frame Border (`\definecolor{PageFrameColor}{HTML}{E2E8F4}`):** Garis bingkai halus di sekeliling halaman.
* **Callout Background (`\definecolor{CalloutBg}{HTML}{EBEFF8}`):** Latar belakang kotak deskripsi judul / abstract box.

### Typography & Layout Constraints
* **Kertas:** A4 (`210mm x 297mm`).
* **Margin:** Top 2.5cm, Bottom 2.5cm, Left 2.5cm, Right 2.5cm.
* **Paragraph Indentation:** Tab diawal paragraf diatur ke `1cm` (`\setlength{\parindent}{1cm}`) menggunakan package `indentfirst`. Paragraf pertama setelah heading wajib menggunakan `\indent`.
* **Header:** Line atas `0.5pt` warna Teal Accent.
  * Kiri: `\lhead{\small\itshape\color{TableHeaderPurple} LUNA -- HOLOGY 9.0}` (Warna Ungu TableHeaderPurple).
  * Kanan: `\rhead{\small\itshape\color{TealAccent} HoloDev Software Development}` (Warna Teal Accent).
* **Footer:** Line bawah `0.5pt` warna Teal Accent. Nomor halaman terpusat di bawah dengan simbol diamond: `\cfoot{\small\color{TealAccent} $\blacklozenge$~\thepage~$\blacklozenge$}`.
* **Maksimal Halaman:** 30 Halaman (Sesuai aturan HOLOGY 9.0).

---

## 3. Custom Commands & Environments

### A. Section Box (`\secbox{RomanNum}{TitleText}`)
Membuat header bab berlatar belakang kotak lavender halus (`SectionBoxBg`) dengan teks biru tua (`PrimaryBlue`) dan garis aksen teal (`TealAccent`) di bawahnya.

### B. Subsection Bar (`\subsecbar{TitleText}`)
Membuat judul sub-bab dengan garis vertikal teal tebal di sebelah kiri yang **ter-center secara vertikal** menyesuaikan tinggi teks (`\ht0` dan `\dp0` bounding box).

### C. Sub-subsection Highlight (`\subsubsecstyle{TitleText}`)
Membuat sub-sub-bab berteks miring berwarna teal (`TealAccent`).

### D. Callout / Abstract Box (`\begin{abstractbox} ... \end{abstractbox}`)
Kotak deskripsi judul/ringkasan berbingkai melengkung (`rounded corners=6pt`, `inner xsep=8pt`, `text width=\dimexpr\textwidth-16pt\relax`), latar `CalloutBg`, dan **tanpa pemotongan kata/hyphenation** (`execute at begin node={\hyphenpenalty=10000\exhyphenpenalty=10000}`).

### E. Tabel Custom (`\begin{tabularx}{\textwidth}{| ... |}`)
Setiap tabel wajib menerapkan standar berikut:
1. `\renewcommand{\arraystretch}{1.35}` untuk padding vertikal sel.
2. `\renewcommand{\tabularxcolumn}[1]{m{#1}}` agar teks sel ter-center secara vertikal (*middle alignment*).
3. `\arrayrulecolor{TableBorderColor}` untuk garis border abu-abu halus.
4. Header baris `\rowcolor{TableHeaderPurple}` dengan teks putih tebal (`\color{white}\bfseries`).
5. Baris genap menggunakan warna `\rowcolor{TableAltRowBg}` (zebra striping).
6. Caption tabel diletakkan **di atas tabel**, terpusat, miring teal dengan pemisah titik (`\captionsetup[table]{format=lunacaption, labelsep=period, position=top}`).

### F. Daftar Pustaka (Harvard Style & Dedicated Page)
1. Diletakkan pada **halaman sendiri (`11_daftar_pustaka.tex`)** yang diawali `\clearpage`.
2. Judul terpusat: `\begin{center}{\Large\bfseries\color{PrimaryBlue} DAFTAR PUSTAKA\par}\end{center}`.
3. Format sitasi gantung (Harvard/APA hanging indent): `\setlength{\leftskip}{1.5em}` dan `\setlength{\parindent}{-1.5em}` tanpa `\noindent`.
4. Menggunakan package `xurl` untuk pemutusan baris URL secara halus tanpa spasi vertikal berlebih.

---

## 4. Rules & Guidelines AI Agent

Saat menulis/memperbarui `.tex` files:
1. **Gunakan Macro yang Sudah Ada:** Selalu gunakan `\secbox`, `\subsecbar`, `\subsubsecstyle`, dan `abstractbox` agar konsistensi desain terjaga. Jangan menulis inline styling ad-hoc secara manual.
2. **Jangan Mengubah Preamble Tanpa Uji Kompilasi:** Setiap perubahan pada `main.tex` harus langsung diuji dengan `pdflatex main.tex`.
3. **Penyusunan Bahasa:** Gunakan Bahasa Indonesia baku sesuai PUEBI/EYD, dengan istilah asing dicetak miring (*italic*).
4. **Sitasi & Referensi:** Gunakan format sitasi standar APA/Harvard `(Penulis, Tahun)`.
5. **Gambar & Diagram:** Masukkan gambar ke direktori `images/`, dan selalu sertakan caption dengan macro caption miring teal.

---

## 5. Perintah Kompilasi (Build Commands)

Kompilasi proposal ke format PDF dapat dilakukan dengan menjalankan shell command:

```bash
pdflatex -interaction=nonstopmode main.tex
```

Hasil PDF akan otomatis dibuat sebagai `main.pdf`.
