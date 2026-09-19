import json
import logging
from typing import Any

from ai.factories.llm_factory import LLMFactory
from ai.interfaces.llm import LLMMessage

logger = logging.getLogger(__name__)

OFFICIAL_DASS21_ITEMS_SPEC: list[dict[str, Any]] = [
    {"item_id": 1, "scale": "stress", "question_text": "Saya merasa sulit untuk beristirahat atau menenangkan diri"},
    {"item_id": 2, "scale": "anxiety", "question_text": "Saya menyadari mulut saya terasa kering"},
    {"item_id": 3, "scale": "depression", "question_text": "Saya sama sekali tidak dapat merasakan perasaan positif"},
    {"item_id": 4, "scale": "anxiety", "question_text": "Saya mengalami kesulitan bernapas (misal napas cepat tanpa aktivitas fisik)"},
    {"item_id": 5, "scale": "depression", "question_text": "Saya merasa sulit berinisiatif untuk melakukan sesuatu"},
    {"item_id": 6, "scale": "stress", "question_text": "Saya cenderung bereaksi berlebihan terhadap suatu situasi"},
    {"item_id": 7, "scale": "anxiety", "question_text": "Saya mengalami gemetar (misalnya pada kedua tangan)"},
    {"item_id": 8, "scale": "stress", "question_text": "Saya merasa menghabiskan banyak energi karena terlalu cemas/gugup"},
    {"item_id": 9, "scale": "anxiety", "question_text": "Saya khawatir terhadap situasi di mana saya mungkin panik atau mempermalukan diri"},
    {"item_id": 10, "scale": "depression", "question_text": "Saya merasa tidak ada lagi hal baik yang bisa saya harapkan di masa depan"},
    {"item_id": 11, "scale": "stress", "question_text": "Saya mendapati diri saya mudah gelisah atau resah"},
    {"item_id": 12, "scale": "stress", "question_text": "Saya merasa sulit untuk rileks atau bersantai"},
    {"item_id": 13, "scale": "depression", "question_text": "Saya merasa sedih, murung, dan tertekan"},
    {"item_id": 14, "scale": "stress", "question_text": "Saya tidak sabar menghadapi hal yang menghambat apa yang sedang saya lakukan"},
    {"item_id": 15, "scale": "anxiety", "question_text": "Saya merasa hampir panik"},
    {"item_id": 16, "scale": "depression", "question_text": "Saya merasa tidak mampu antusias terhadap hal apa pun"},
    {"item_id": 17, "scale": "depression", "question_text": "Saya merasa bahwa diri saya tidak berharga"},
    {"item_id": 18, "scale": "stress", "question_text": "Saya merasa mudah tersinggung atau sensitif"},
    {"item_id": 19, "scale": "anxiety", "question_text": "Saya menyadari detak jantung saya berdegup kencang tanpa alasan fisik"},
    {"item_id": 20, "scale": "anxiety", "question_text": "Saya merasa takut tanpa alasan yang jelas"},
    {"item_id": 21, "scale": "depression", "question_text": "Saya merasa bahwa hidup ini tidak berarti"},
]


class DASSExtractionService:
    """Service untuk mengekstrak indikasi 21 butir DASS-21 dari transkrip percakapan

    secara cerdas menggunakan Large Language Model.
    """

    def __init__(self, llm_provider=None):
        self.llm_provider = llm_provider or LLMFactory.get_provider()

    async def extract_from_transcript(self, transcript_text: str) -> list[dict[str, Any]]:
        """Menganalisis transkrip percakapan dan menghasilkan array 21 butir DASS-21

        lengkap dengan skor (0-3), kutipan bukti ('evidence'), dan 'confidence'.
        """
        if not transcript_text or not transcript_text.strip():
            logger.info("ℹ️ [DASS EXTRACTION] Empty transcript provided, returning default items.")
            return self._build_default_items()

        items_spec_str = json.dumps(OFFICIAL_DASS21_ITEMS_SPEC, ensure_ascii=False, indent=2)

        system_prompt = LLMMessage(
            role="system",
            content=(
                "Anda adalah sistem penilai psikometris DASS-21 (Depression Anxiety Stress Scale 21) klinis LUNA AI. "
                "Tugas Anda adalah membaca transkrip dialog percakapan antara pengguna dan Luna AI, "
                "kemudian menilai sejauh mana pengguna menunjukkan keluhan untuk ke-21 butir DASS-21 berikut:\n\n"
                f"{items_spec_str}\n\n"
                "ATURAN PENILAIAN:\n"
                "1. Skala skor tiap butir adalah integer 0 sampai 3:\n"
                "   - 0: Tidak pernah dialami / tidak ada bukti sama sekali dalam transkrip.\n"
                "   - 1: Kadang-kadang / keluhan ringan sepintas.\n"
                "   - 2: Sering / keluhan tampak jelas dan mengganggu.\n"
                "   - 3: Hampir selalu / intensitas keluhan sangat berat atau berulang.\n"
                "2. JIKA butir tidak pernah disinggung atau tidak ada indikasi dalam teks, WAJIB beri skor 0, evidence: null, confidence: 0.0.\n"
                "3. JIKA butir terindikasi (skor >= 1), sertakan kutipan kalimat pengguna yang paling relevan pada field 'evidence', dan confidence (float 0.50 s.d 1.00).\n"
                "4. WAJIB mengembalikan JSON ARRAY VALID yang berisi TEPAT 21 objek (item_id 1 s.d 21) TANPA MARKDOWN (tanpa ```json atau teks lain).\n"
                "Format setiap elemen array:\n"
                "{\n"
                '  "item_id": <int 1-21>,\n'
                '  "scale": "<stress | anxiety | depression>",\n'
                '  "question_text": "<teks resmi>",\n'
                '  "score": <int 0-3>,\n'
                '  "evidence": "<kutipan kalimat user atau null>",\n'
                '  "confidence": <float 0.0 - 1.0>,\n'
                '  "is_user_edited": false\n'
                "}"
            ),
        )

        user_prompt = LLMMessage(
            role="user",
            content=f"Berikut adalah transkrip percakapan yang perlu dinilai ke dalam 21 butir DASS-21:\n\n{transcript_text}",
        )

        try:
            tokens = []
            async for token in self.llm_provider.stream_response([system_prompt, user_prompt]):
                tokens.append(token)

            raw_resp = "".join(tokens).strip()
            if raw_resp.startswith("```"):
                raw_resp = raw_resp.split("```")[1]
                if raw_resp.startswith("json"):
                    raw_resp = raw_resp[4:]
            raw_resp = raw_resp.strip()

            parsed = json.loads(raw_resp)
            if isinstance(parsed, list) and len(parsed) > 0:
                # Validasi dan normalize
                parsed_map = {it.get("item_id"): it for it in parsed if isinstance(it, dict)}
                final_items = []
                for spec in OFFICIAL_DASS21_ITEMS_SPEC:
                    i_id = spec["item_id"]
                    if i_id in parsed_map:
                        item_data = parsed_map[i_id]
                        final_items.append({
                            "item_id": i_id,
                            "scale": spec["scale"],
                            "question_text": spec["question_text"],
                            "score": min(3, max(0, int(item_data.get("score", 0)))),
                            "evidence": item_data.get("evidence"),
                            "confidence": float(item_data.get("confidence", 0.0)),
                            "is_user_edited": False,
                        })
                    else:
                        final_items.append({
                            "item_id": i_id,
                            "scale": spec["scale"],
                            "question_text": spec["question_text"],
                            "score": 0,
                            "evidence": None,
                            "confidence": 0.0,
                            "is_user_edited": False,
                        })
                logger.info("✅ [DASS EXTRACTION SUCCESS] Successfully extracted 21 DASS items via LLM.")
                return final_items

        except Exception as e:
            logger.error(f"⚠️ [DASS EXTRACTION ERROR] Failed to extract DASS via LLM: {e}. Falling back to default.")

        return self._build_default_items()

    def _build_default_items(self) -> list[dict[str, Any]]:
        return [
            {
                "item_id": item["item_id"],
                "scale": item["scale"],
                "question_text": item["question_text"],
                "score": 0,
                "evidence": None,
                "confidence": 0.0,
                "is_user_edited": False,
            }
            for item in OFFICIAL_DASS21_ITEMS_SPEC
        ]
