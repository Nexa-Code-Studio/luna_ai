# 🐳 Panduan Setup Docker (Ringan, Cepat & Hot-Reload) - LUNA AI

Dokumen ini berisi panduan lengkap setup Docker yang **ringan, cepat, dan terintegrasi dalam 1 berkas** untuk monorepo **LUNA AI**. Panduan ini sudah mencakup konfigurasi `Dockerfile` (`api`, `mcp`, `workers`), `docker-compose.yml`, `.dockerignore`, serta script runner otomatisasi `scripts/docker-dev.sh` & `scripts/docker-dev.ps1`.

---

## 📑 Daftar Isi
1. [Keunggulan Setup Ringan & Cepat](#-keunggulan-setup-ringan--cepat)
2. [Prasyarat](#-prasyarat)
3. [Struktur File](#-struktur-file)
4. [Konfigurasi & Script](#-konfigurasi--script)
   - [1. Backend API Dockerfile (`apps/backend/api/Dockerfile`)](#1-backend-api-dockerfile-appsbackendapidockerfile)
   - [2. Docker Ignore (`.dockerignore`)](#2-docker-ignore-dockerignore)
   - [3. Docker Compose (`docker-compose.yml`)](#3-docker-compose-docker-composeyml)
   - [4. Runner Script (`scripts/docker-dev.sh` & `scripts/docker-dev.ps1`)](#4-runner-script-scriptsdocker-devsh--scriptsdocker-devps1)
5. [Cara Penggunaan / Cara Jalankan](#-cara-penggunaan--cara-jalankan)
6. [Perintah Praktis (Cheat Sheet)](#-perintah-praktis-cheat-sheet)

---

## ⚡ Keunggulan Setup Ringan & Cepat

- **`slim` Base Images**: Menggunakan Python `3.11-slim` & Alpine images (`postgres:16-alpine`, `redis:7-alpine`) untuk memangkas ukuran image hingga 70%.
- **Layer Caching**: Editable package installs (`pip install -e`) dipisah agar build cache tetap efisien.
- **Volume Binding**: Direct volume mount (`.:/workspace`) untuk mendukung **Hot-Reloading** secara langsung saat kode Python diubah.
- **Interactive Log Stream & Auto-Shutdown**: Runner script menyajikan log berwarna dari seluruh service langsung di terminal Anda dan otomatis shutdown (`docker compose down`) saat menekan **`Ctrl + C`**.

---

## 📋 Prasyarat

Pastikan perangkat Anda sudah terinstall:
- **Docker Engine** (v20.10+)
- **Docker Compose** (v2.0+)

---

## 📁 Struktur File

```text
luna_ai/
├── apps/
│   └── backend/
│       ├── api/Dockerfile
│       ├── mcp/Dockerfile
│       └── workers/Dockerfile
├── docker-compose.yml
├── .dockerignore
├── .env
├── scripts/
│   ├── docker-dev.sh
│   └── docker-dev.ps1
└── DOCKER_SETUP.md
```

---

## 🚀 Cara Penggunaan / Cara Jalankan

### Cara 1: Menggunakan Runner Script (Rekomendasi)

- **Linux / macOS**:
  ```bash
  chmod +x scripts/docker-dev.sh
  ./scripts/docker-dev.sh
  ```

- **Windows PowerShell**:
  ```powershell
  .\scripts\docker-dev.ps1
  ```

> *Seluruh log dari FastAPI, FastMCP, Worker, PostgreSQL, Redis, dan Qdrant akan tampil secara live di terminal Anda. Tekan `Ctrl + C` untuk menghentikan seluruh service secara otomatis.*

---

### Cara 2: Menggunakan Docker Compose Manual

- **Menjalankan di Foreground (Interactive Logs + Auto Stop Ctrl+C)**:
  ```bash
  docker compose up --build
  ```
- **Menjalankan di Background (Detached Mode)**:
  ```bash
  docker compose up -d
  ```
- **Rebuild Image (Jika ada penambahan dependency baru)**:
  ```bash
  docker compose up --build
  ```

---

## 💡 Perintah Praktis (Cheat Sheet)

| Service | Container Port | Host Port | Description |
| :--- | :--- | :--- | :--- |
| **FastAPI Backend (`luna_api`)** | `8888` | `8888` | Main API & Auth Endpoints |
| **FastMCP Server (`luna_mcp`)** | `8889` | `8889` | Model Context Protocol SSE Server |
| **PostgreSQL (`luna_postgres`)** | `5432` | `5433` | Primary Database (Host mapped to 5433) |
| **Redis Cache/Queue (`luna_redis`)** | `6379` | `6380` | ARQ Task Queue & Cache (Host mapped to 6380) |
| **Qdrant Vector DB (`luna_qdrant`)** | `6333` | `6333` | Vector Search Engine |

---
*Dokumen ini dibuat otomatis untuk penyiapan lingkungan Docker LUNA AI yang ringan, cepat, dan siap pakai.*
