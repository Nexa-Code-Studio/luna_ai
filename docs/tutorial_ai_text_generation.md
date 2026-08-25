# Tutorial: Cara Menggunakan AI Text Generator (`packages/ai`)

> **Panduan untuk Developer:** Tutorial ini menjelaskan cara mengakses modul AI Text Generation di monorepo `luna_ai`. Dengan abstraksi ini, Anda dapat menggunakan LLM (OpenAI GPT-4o, Google Gemini, atau Mock lokal) serta mengintegrasikan konteks RAG / Qdrant hanya dengan memanggil `LLMFactory`.

---

## 🚀 1. Persiapan Singkat

Pastikan environment Python sudah diaktifkan dan file `.env` sudah dikonfigurasi di root project:

```bash
# Aktifkan virtual environment
source .venv/bin/activate
```

Di file `.env`, atur provider LLM yang ingin Anda gunakan:

```env
# Pilihan provider: mock | openai | gemini
LLM_PROVIDER=mock

# Kunci API (Hanya jika menggunakan provider openai atau gemini)
LLM_API_KEY=sk-proj-...
GEMINI_API_KEY=AIzaSy...
```

> 💡 **Tips:** Gunakan `LLM_PROVIDER=mock` jika Anda ingin melakukan tes/pengembangan lokal tanpa memerlukan kunci API (gratis dan cepat).

---

## 📝 2. Contoh Penggunaan Dasar (Generate Text Sekaligus)

Untuk menghasilkan respons teks utuh dari AI:

```python
import asyncio
from packages.ai import LLMFactory, LLMMessage


async def main():
    # 1. Ambil instance provider otomatis berdasarkan .env
    llm = LLMFactory.get_provider()

    # 2. Buat daftar pesan (role: "system", "user", atau "assistant")
    messages = [
        LLMMessage(
            role="system",
            content="Kamu adalah LUNA, asisten AI konseling yang empati dan hangat."
        ),
        LLMMessage(
            role="user",
            content="Saya merasa sangat cemas menghadapi ujian besok."
        )
    ]

    # 3. Panggil generate_response
    response_text = await llm.generate_response(messages, temperature=0.7)

    print("=== Respons AI ===")
    print(response_text)


if __name__ == "__main__":
    asyncio.run(main())
```

---

## 🌊 3. Contoh Streaming Response (Real-Time Tokens)

Jika Anda ingin menampilkan jawaban AI kata-demi-kata (efek mengetik / real-time streaming untuk UI/WebSocket):

```python
import asyncio
from packages.ai import LLMFactory, LLMMessage


async def stream_demo():
    llm = LLMFactory.get_provider()

    messages = [
        LLMMessage(role="user", content="Berikan 3 tips singkat mengatasi panik.")
    ]

    print("=== AI Stream Output ===")
    # Gunakan stream_response dengan async for
    async for token in llm.stream_response(messages):
        print(token, end="", flush=True)
    print()


if __name__ == "__main__":
    asyncio.run(stream_demo())
```

---

## 🔍 4. Menggunakan RAG Context dari Qdrant & Knowledge Base

Untuk memberikan konteks dari **Qdrant Vector Database** (artikel psikoedukasi/koping) atau **User Memory** ke dalam prompt AI:

```python
import asyncio
from packages.ai import LLMFactory, LLMMessage


async def rag_demo():
    llm = LLMFactory.get_provider()

    # 1. Dokumen yang diambil dari Qdrant (Knowledge & Memories)
    retrieved_knowledge = [
        "Teknik Pernapasan 4-7-8: Tarik napas 4 detik, tahan 7 detik, hembuskan 8 detik."
    ]
    retrieved_memories = [
        "User (Sarah) merasa terbantu ketika minum teh hangat saat cemas."
    ]

    # 2. Format konteks ke System Message
    context_str = (
        "=== PENGETAHUAN PENDUKUNG (RAG KNOWLEDGE) ===\n"
        + "\n".join(f"- {k}" for k in retrieved_knowledge)
        + "\n\n=== MEMORI PENGGUNA (USER MEMORY) ===\n"
        + "\n".join(f"- {m}" for m in retrieved_memories)
    )

    messages = [
        LLMMessage(
            role="system",
            content=f"Kamu adalah LUNA AI Counselor.\n\n{context_str}"
        ),
        LLMMessage(
            role="user",
            content="Dada saya terasa sesak karena cemas, apa yang harus saya lakukan?"
        )
    ]

    response = await llm.generate_response(messages)
    print("=== Respons AI dengan Konteks RAG ===")
    print(response)


if __name__ == "__main__":
    asyncio.run(rag_demo())
```

---

## 🎯 5. Meminta Output Format JSON & Parameter Khusus Provider

Bagaimana jika Anda ingin respons AI berformat **JSON** (misal untuk ekstraksi emosi/worker) atau menggunakan parameter spesifik vendor?

### A. Meminta Output Format JSON (`response_format="json"`)
Gunakan parameter standar `response_format="json"`. Masing-masing provider secara otomatis memetakannya ke opsi spesifik vendor:
- OpenAI $\rightarrow$ `response_format={"type": "json_object"}`
- Gemini $\rightarrow$ `response_mime_type="application/json"`
- Mock $\rightarrow$ Mengembalikan contoh JSON string yang valid.

```python
import asyncio
import json
from packages.ai import LLMFactory, LLMMessage


async def json_output_demo():
    llm = LLMFactory.get_provider()

    messages = [
        LLMMessage(
            role="system",
            content="Jawab HANYA dalam format JSON valid dengan field: status, mood, score."
        ),
        LLMMessage(role="user", content="Saya merasa agak cemas tapi tetap optimis.")
    ]

    # Cukup teruskan response_format="json"
    raw_json = await llm.generate_response(messages, response_format="json")

    print("=== Raw JSON Output ===")
    print(raw_json)

    # Parsing ke Python Dictionary
    data = json.loads(raw_json)
    print("Parsed Mood:", data.get("mood"))


if __name__ == "__main__":
    asyncio.run(json_output_demo())
```

### B. Meneruskan Parameter Spesifik Provider (`**kwargs`)
Jika Anda ingin mengirim parameter khusus vendor (misal `seed`, `top_p`, `frequency_penalty`), Anda bisa meneruskannya via `**kwargs`:

```python
# Menentukan seed & top_p secara spesifik
response = await llm.generate_response(
    messages,
    temperature=0.2,
    seed=42,           # Parameter khusus OpenAI/Gemini
    top_p=0.9
)
```

---

## 🔀 6. Cara Mengganti Provider AI (Tanpa Ubah Kode Python)

Cukup ubah file `.env`:

### OpenAI (GPT-4o)
```env
LLM_PROVIDER=openai
LLM_API_KEY=sk-proj-your-openai-key
LLM_MODEL=gpt-4o
```

### Google Gemini (Gemini Flash/Pro)
```env
LLM_PROVIDER=gemini
GEMINI_API_KEY=AIzaSy-your-gemini-key
GEMINI_MODEL=gemini-1.5-flash
```

### Testing Offline (Mock)
```env
LLM_PROVIDER=mock
```

---

## 🛠️ 7. Memaksa Provider Tertentu di Kode (Override .env)

```python
# Memaksa menggunakan OpenAI secara eksplisit
openai_llm = LLMFactory.get_provider("openai")

# Memaksa menggunakan Gemini secara eksplisit
gemini_llm = LLMFactory.get_provider("gemini")

# Memaksa menggunakan Mock secara eksplisit
mock_llm = LLMFactory.get_provider("mock")
```

---

## ❓ FAQ & Troubleshooting

* **Q: Saya mendapat error `ModuleNotFoundError: No module named 'packages'`?**  
  * **Solusi:** Jalankan script Python dengan menentukan `PYTHONPATH=.`, contoh: `PYTHONPATH=. python script.py`.

* **Q: Error `ValueError: OpenAI API Key is missing`?**  
  * **Solusi:** Pastikan `LLM_API_KEY` terisi di `.env`, atau gunakan `LLM_PROVIDER=mock` untuk pengujian gratis tanpa API key.
