import enum
import re
from typing import NamedTuple


class ConversationIntent(enum.Enum):
    EMOTIONAL_LISTENING = "emotional_listening"
    CONVERSATION_CONTINUATION = "conversation_continuation"
    FACTUAL_OR_PSYCHOEDUCATION = "factual_or_psychoeducation"
    TECHNIQUE_OR_HOW_TO = "technique_or_how_to"
    SAFETY_CRITICAL = "safety_critical"
    CASUAL_GREETING = "casual_greeting"


class IntentGatingResult(NamedTuple):
    intent: ConversationIntent
    should_retrieve_rag: bool
    reason: str


# Heuristic patterns for intent classification (fast, deterministic, zero latency)
_KNOWLEDGE_PATTERNS = [
    re.compile(r"\b(apa itu|pengertian|definisi|maksud dari|arti dari|kenapa|mengapa|apa penyebab)\b", re.IGNORECASE),
    re.compile(r"\b(gejala|tanda-tanda|ciri-ciri|faktor risiko|dampak dari)\b", re.IGNORECASE),
    re.compile(r"\b(gangguan kecemasan|depresi mayor|bipolar|ptsd|ocd|skizofrenia|panic attack|serangan panik)\b", re.IGNORECASE),
]

_TECHNIQUE_PATTERNS = [
    re.compile(r"\b(bagaimana cara|gimana cara|cara melakukan|latihan|teknik|metode|tips|langkah)\b", re.IGNORECASE),
    re.compile(r"\b(grounding|pernapasan|relaksasi|journaling|mindfulness|meditasi|4-7-8|5-4-3-2-1|otogenik)\b", re.IGNORECASE),
    re.compile(r"\b(tolong ajarin|bantu aku tenang|kasih saran buat menenangkan)\b", re.IGNORECASE),
]

_CONTINUATION_PATTERNS = [
    re.compile(r"^(iya|ya|nggak|tidak|betul|bener|itu|tadi|yang tadi|maksudku|jadi|terus|nah)\b", re.IGNORECASE),
    re.compile(r"\b(yang tadi itu|seperti itu|yang kubilang tadi|lanjutkan|terus gimana)\b", re.IGNORECASE),
]

_GREETING_PATTERNS = [
    re.compile(r"^(halo|hai|pagi|selamat pagi|selamat siang|selamat sore|selamat malam|assalamualaikum|tes)\b", re.IGNORECASE),
]


class RAGGatingService:
    """Lightweight intent-based gating to decide whether Qdrant knowledge retrieval

    is truly appropriate, avoiding encyclopedic knowledge dumps during emotional conversations.
    """

    @classmethod
    def evaluate_intent(cls, user_text: str, is_crisis: bool = False) -> IntentGatingResult:
        clean = user_text.strip()
        if not clean:
            return IntentGatingResult(
                ConversationIntent.CASUAL_GREETING, False, "Empty user text"
            )

        if is_crisis:
            return IntentGatingResult(
                ConversationIntent.SAFETY_CRITICAL, False, "Safety gate crisis intervention active"
            )

        # 1. Check for casual greetings
        if len(clean.split()) <= 3 and any(p.search(clean) for p in _GREETING_PATTERNS):
            return IntentGatingResult(
                ConversationIntent.CASUAL_GREETING, False, "Short greeting does not require RAG"
            )

        # 2. Check for conversation continuations or short answers
        if any(p.search(clean) for p in _CONTINUATION_PATTERNS) and len(clean.split()) <= 6:
            return IntentGatingResult(
                ConversationIntent.CONVERSATION_CONTINUATION, False, "Continuation referent requires conversational history, not RAG"
            )

        # 3. Check for factual questions / psychoeducation (e.g. "apa itu", "kenapa")
        if any(p.search(clean) for p in _KNOWLEDGE_PATTERNS):
            return IntentGatingResult(
                ConversationIntent.FACTUAL_OR_PSYCHOEDUCATION, True, "User requested psychoeducation or factual information"
            )

        # 4. Check for technique or coping skills requests (e.g. "bagaimana cara", "latihan")
        if any(p.search(clean) for p in _TECHNIQUE_PATTERNS):
            return IntentGatingResult(
                ConversationIntent.TECHNIQUE_OR_HOW_TO, True, "User requested mental health technique or exercise instructions"
            )

        # 5. Default: Emotional venting / personal narrative
        return IntentGatingResult(
            ConversationIntent.EMOTIONAL_LISTENING, False, "Personal emotional narrative; prioritize empathy and conversational presence"
        )
