# 📊 Luna AI VPS Concurrency & Stress Test Report

- **Execution Date**: `2026-09-20 19:37:48`
- **Target VPS**: `https://luna.nexacode.dev`
- **Concurrent Users**: `10`
- **Total Turns**: `10` (Success rate: `100.0%`)
- **Total Audio Uploaded**: `60.82 MB`
- **Avg Auth Latency**: `845.2 ms`
- **🗣️ Durasi Mock User Berbicara**: `33.22 detik`
- **📤 Waktu Pengiriman Audio Mock User**: `3.89 detik`
- **⏱️ Rata-rata Jeda User Menunggu Hingga AI Mulai Bicara (TTFA)**: `1.07 detik` (1066 ms) *(Min: 0.56s, Max: 1.84s)*
- **🔊 Rata-rata Durasi AI Selesai Seluruh Kalimat**: `9.13 detik` (9126 ms)

## Per-User Results Breakdown

| User | Auth (ms) | WS Handshake (ms) | User Bicara | Waktu Kirim | ⏱️ Jeda User Menunggu (TTFA) | 🔊 AI Selesai Bicara |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| User 01 | 484.2 | 275.9 | 33.2s | 3.54s | **0.62s** (615 ms) | 9.29s (9292 ms) |
| User 02 | 561.6 | 208.0 | 33.2s | 3.69s | **1.08s** (1081 ms) | 9.32s (9324 ms) |
| User 03 | 318.9 | 197.6 | 33.2s | 1.65s | **0.56s** (556 ms) | 8.34s (8342 ms) |
| User 04 | 482.0 | 277.3 | 33.2s | 3.65s | **0.92s** (924 ms) | 8.24s (8243 ms) |
| User 05 | 371.6 | 245.3 | 33.2s | 6.26s | **1.50s** (1505 ms) | 7.78s (7776 ms) |
| User 06 | 371.6 | 245.3 | 33.2s | 5.78s | **1.19s** (1195 ms) | 9.91s (9906 ms) |
| User 07 | 1404.0 | 454.0 | 33.2s | 2.67s | **0.95s** (948 ms) | 10.43s (10427 ms) |
| User 08 | 1420.6 | 394.0 | 33.2s | 3.58s | **1.28s** (1280 ms) | 10.65s (10647 ms) |
| User 09 | 1508.1 | 384.6 | 33.2s | 3.50s | **0.72s** (722 ms) | 8.23s (8228 ms) |
| User 10 | 1529.3 | 328.4 | 33.2s | 4.57s | **1.84s** (1840 ms) | 9.08s (9075 ms) |

