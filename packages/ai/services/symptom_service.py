import logging
import re
from typing import Dict, List, Any

from shared.domain_types import (
    ExtractedSymptomEvidence,
    SymptomDuration,
    SymptomExtractionResult,
)

logger = logging.getLogger(__name__)

SYMPTOM_TAXONOMY: List[Dict[str, Any]] = [
    # Somatic Category
    {
        "code": "sleep_disturbance",
        "name": "Kesulitan Tidur / Insomnia",
        "category": "somatic",
        "keywords": ["susah tidur", "tidak bisa tidur", "insomnia", "terbangun malam", "sulit tidur", "hampir tiap malam susah tidur"],
        "severity": "moderate",
    },
    {
        "code": "fatigue",
        "name": "Kelelahan / Low Energy",
        "category": "somatic",
        "keywords": ["capek", "lelah", "kehabisan energi", "lemas", "tidak bertenaga", "sangat lelah", "capek banget"],
        "severity": "mild",
    },
    {
        "code": "breathing_difficulty",
        "name": "Sesak Napas / Breathlessness",
        "category": "somatic",
        "keywords": ["sesak napas", "sulit bernapas", "terengah-engah", "napas pendek", "kesulitan bernapas"],
        "severity": "moderate",
    },
    {
        "code": "palpitations",
        "name": "Detak Jantung Berdebar",
        "category": "somatic",
        "keywords": ["detak jantung", "berdebar", "jantung berdebar", "dada berdebar"],
        "severity": "moderate",
    },
    {
        "code": "dry_mouth",
        "name": "Mulut/Rongga Kering",
        "category": "somatic",
        "keywords": ["mulut kering", "rongga mulut kering"],
        "severity": "mild",
    },
    {
        "code": "trembling",
        "name": "Gemetar pada Tangan/Tubuh",
        "category": "somatic",
        "keywords": ["gemetar", "tangan gemetar", "tubuh bergetar"],
        "severity": "mild",
    },
    {
        "code": "physical_tension",
        "name": "Ketegangan Otot & Leher",
        "category": "somatic",
        "keywords": ["otot tegang", "leher tegang", "bahu tegang", "otot kaku"],
        "severity": "mild",
    },
    # Cognitive Category
    {
        "code": "hopelessness",
        "name": "Keputusasaan / No Future",
        "category": "cognitive",
        "keywords": ["tidak ada harapan", "putus asa", "gak ada masa depan", "tidak ada masa depan", "tidak ada lagi yang bisa diharapkan", "capek hidup", "capek banget hidup", "kalau aku gak ada", "kalau aku tidak ada", "kalau aku nggak ada", "lebih baik kalau aku tidak ada", "lebih baik kalau aku nggak ada", "lebih baik kalau aku gak ada"],
        "severity": "severe",
    },
    {
        "code": "worthlessness",
        "name": "Merasa Tidak Berharga",
        "category": "cognitive",
        "keywords": ["tidak berharga", "gak guna", "tidak berguna", "beban", "diri saya tidak berharga", "merasa kecil", "salah terus", "merasa salah", "semua orang lebih baik", "semua orang bakal lebih baik"],
        "severity": "severe",
    },

    {
        "code": "meaninglessness",
        "name": "Hidup Tidak Berarti",
        "category": "cognitive",
        "keywords": ["hidup tidak berarti", "hidup gak ada artinya", "tanpa arti", "hidup ini tidak berarti"],
        "severity": "severe",
    },
    {
        "code": "mental_hooking",
        "name": "Pikiran Menjebak / Overthinking",
        "category": "cognitive",
        "keywords": ["overthinking", "pikiran menjebak", "kepikiran terus", "kepikiran", "kepikrian", "terjebak pikiran"],
        "severity": "moderate",
    },

    {
        "code": "social_panic_worry",
        "name": "Takut Mempermalukan Diri",
        "category": "cognitive",
        "keywords": ["takut panik", "mempermalukan diri", "lakukan hal bodoh"],
        "severity": "moderate",
    },
    {
        "code": "unexplained_fear",
        "name": "Rasa Takut Tanpa Alasan",
        "category": "cognitive",
        "keywords": ["takut tanpa alasan", "takut tanpa pemicu"],
        "severity": "moderate",
    },
    # Emotional Category
    {
        "code": "persistent_sadness",
        "name": "Kesedihan Persisten / Dysphoria",
        "category": "emotional",
        "keywords": ["sedih", "murung", "tertekan", "down", "merasa sedih"],
        "severity": "moderate",
    },
    {
        "code": "anhedonia",
        "name": "Kehilangan Minat / Semangat",
        "category": "emotional",
        "keywords": ["kehilangan minat", "tidak tertarik", "nggak tertarik", "gak ada semangat", "hilang semangat", "tidak tertarik melakukan"],
        "severity": "moderate",
    },
    {
        "code": "irritability",
        "name": "Sensitif / Mudah Tersinggung",
        "category": "emotional",
        "keywords": ["mudah tersinggung", "gampang marah", "sensitif", "marahan", "mudah tersentuh"],
        "severity": "mild",
    },
    {
        "code": "difficulty_relaxing",
        "name": "Sulit Rileks & Tenang",
        "category": "emotional",
        "keywords": ["sulit tenang", "susah rileks", "gak bisa santai", "tegang terus", "sulit untuk rileks"],
        "severity": "mild",
    },
    {
        "code": "overwhelming_emotions",
        "name": "Badai Emosional Campur Aduk",
        "category": "emotional",
        "keywords": ["badai emosional", "emosi campur aduk", "emosi membingungkan"],
        "severity": "moderate",
    },
    # Behavioral Category
    {
        "code": "social_withdrawal",
        "name": "Menarik Diri dari Sosial",
        "category": "behavioral",
        "keywords": ["males ketemu orang", "males ketemu teman", "males banget ketemu", "nggak tertarik ketemu", "menarik diri", "mengurung diri", "gak mau ketemu teman", "males ketemu"],
        "severity": "moderate",
    },

    {
        "code": "avolition",
        "name": "Sulit Berinisiatif",
        "category": "behavioral",
        "keywords": ["sulit berinisiatif", "berat untuk mulai", "sulit dapat semangat untuk melakukan"],
        "severity": "moderate",
    },
]


class SymptomService:
    """
    Service Layer for extracting symptoms and temporal evidence from natural user text.

    Note: Symptom extraction represents natural speech evidence only and does NOT
    constitute a clinical diagnosis.
    """

    def extract_symptoms(self, text: str) -> SymptomExtractionResult:
        """
        Extracts structured symptoms, quotes, categories, and duration from user text.
        """
        if not text or not text.strip():
            return SymptomExtractionResult(extracted_symptoms=[])

        lower_text = text.lower()
        extracted: List[ExtractedSymptomEvidence] = []
        seen_codes = set()

        # 1. Match symptom keywords
        for item in SYMPTOM_TAXONOMY:
            code = item["code"]
            if code in seen_codes:
                continue

            for kw in item["keywords"]:
                if kw in lower_text:
                    seen_codes.add(code)
                    
                    # Extract surrounding phrase quote (approximate)
                    pattern = re.compile(rf"([^.!?]*?{re.escape(kw)}[^.!?]*?)", re.IGNORECASE)
                    match = pattern.search(text)
                    quote = match.group(1).strip() if match else kw

                    extracted.append(
                        ExtractedSymptomEvidence(
                            symptom_code=code,
                            symptom_name=item["name"],
                            category=item["category"],
                            user_quote=quote,
                            confidence=0.90,
                            severity_signal=item["severity"],
                        )
                    )
                    break

        # 2. Extract duration representation
        duration = SymptomDuration.UNSPECIFIED
        if any(w in lower_text for w in ["sebulan", "1 bulan", "berbulan-bulan", "3 minggu", "4 minggu", "beberapa minggu"]):
            duration = SymptomDuration.ONE_MONTH_OR_MORE
        elif any(w in lower_text for w in ["seminggu", "1 minggu", "2 minggu", "dua minggu"]):
            duration = SymptomDuration.ONE_TO_TWO_WEEKS
        elif any(w in lower_text for w in ["bertahun-tahun", "bertahun tahun"]):
            duration = SymptomDuration.CHRONIC
        elif any(w in lower_text for w in ["baru saja", "kemarin", "hari ini"]):
            duration = SymptomDuration.RECENT

        # 3. Compute domain signal flags
        categories = {e.category for e in extracted}
        return SymptomExtractionResult(
            extracted_symptoms=extracted,
            duration=duration,
            has_somatic_signals="somatic" in categories,
            has_cognitive_signals="cognitive" in categories,
            has_emotional_signals="emotional" in categories,
            has_behavioral_signals="behavioral" in categories,
        )
