"""
Unit tests for Luna AI Prompt V2 and 5-layer instruction architecture.
Tests run using standard library unittest (no external pytest dependency required).
"""

import unittest
from unittest.mock import MagicMock, patch

from apps.backend.api.app.core.prompt_templates import (
    LUNA_SYSTEM_PROMPT,
    LUNA_SYSTEM_PROMPT_V1,
    LUNA_SYSTEM_PROMPT_V2,
    get_luna_system_prompt,
)
from packages.ai.orchestration.orchestrator import AIOrchestrator
from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.shared.config import settings
from shared.domain_types import (
    EmotionDetectionResult,
    RiskAssessmentOutput,
    SafetyGateInput,
    SafetyPolicyDecision,
)


class MockLLM(BaseLLMProvider):
    async def generate_response(self, messages: list[LLMMessage], **kwargs) -> str:
        return "Aku di sini mendengarkanmu."

    async def stream_response(self, messages: list[LLMMessage], **kwargs):
        yield "Aku di sini mendengarkanmu."


class TestPromptAndOrchestratorV2(unittest.TestCase):
    def setUp(self):
        self.mock_llm = MockLLM()
        self.orchestrator = AIOrchestrator(llm_provider=self.mock_llm)

    def test_prompt_template_versioning(self):
        """Prompt templates provide V1 and V2, defaulting to V2."""
        self.assertEqual(get_luna_system_prompt("v1"), LUNA_SYSTEM_PROMPT_V1)
        self.assertEqual(get_luna_system_prompt("v2"), LUNA_SYSTEM_PROMPT_V2)
        self.assertEqual(LUNA_SYSTEM_PROMPT, LUNA_SYSTEM_PROMPT_V2)
        self.assertIn("LAYER 1", LUNA_SYSTEM_PROMPT_V2)
        self.assertIn("LAYER 2", LUNA_SYSTEM_PROMPT_V2)
        self.assertIn("LAYER 3", LUNA_SYSTEM_PROMPT_V2)
        self.assertIn("LAYER 4", LUNA_SYSTEM_PROMPT_V2)
        self.assertIn("LAYER 5", LUNA_SYSTEM_PROMPT_V2)

    def test_orchestrator_compose_prompt_5_layers(self):
        """_compose_system_prompt produces all 5 instruction layers under V2."""
        emotion = EmotionDetectionResult(
            primary_emotion="sad",
            confidence=0.88,
            scores={"sad": 0.88},
            latency_ms=12.5,
        )
        safety = MagicMock(
            risk_level="low",
            response_policy="NORMAL_RAG",
        )
        rag_items = [{"title": "Coping Stress", "content": "Tarik napas dalam-dalam secara perlahan."}]
        dass_scores = {"depression": 12, "anxiety": 6, "stress": 8}

        prompt = self.orchestrator._compose_system_prompt(
            emotion=emotion,
            safety_decision=safety,
            rag_items=rag_items,
            dass_scores=dass_scores,
            user_name="Budi",
            persisted_memory="Suka bermusik dan main gitar.",
        )

        # Layer 1 checks
        self.assertIn("[LAYER 1 — IDENTITAS & PERAN LUNA]", prompt)
        self.assertIn("Budi", prompt)
        self.assertIn("bukan tenaga medis", prompt)

        # Layer 2 checks
        self.assertIn("[LAYER 2 — PRIORITAS PERCAKAPAN & KONTEKS]", prompt)
        self.assertIn("Tanggapi langsung ucapan terbaru", prompt)
        self.assertIn("DILARANG KERAS mengutip", prompt)
        self.assertIn("Suka bermusik dan main gitar.", prompt)
        self.assertIn("Coping Stress", prompt)

        # Layer 3 checks
        self.assertIn("[LAYER 3 — SAFETY & GROUNDING]", prompt)
        self.assertIn("sad", prompt)
        self.assertIn("DILARANG KERAS menyebutkan skor", prompt)

        # Layer 4 checks
        self.assertIn("[LAYER 4 — BAHASA INDONESIA PERCAKAPAN (SPOKEN INDONESIAN)]", prompt)
        self.assertIn("Default 1 hingga 3 kalimat pendek", prompt)
        self.assertIn("MAKSIMAL SATU pertanyaan lanjutan", prompt)

        # Layer 5 checks
        self.assertIn("[LAYER 5 — DELIVERY SUARA & AUDIO TAGS (ELEVENLABS v4 TURBO)]", prompt)
        self.assertIn("rekomendasi nada: soft", prompt)
        self.assertIn("[softly]", prompt)
        self.assertIn("DILARANG KERAS tag negatif", prompt)
        self.assertIn("DILARANG simbol Markdown", prompt)

    def test_v1_rollback_switch(self):
        """Switching LUNA_PROMPT_VERSION to 'v1' produces legacy prompt."""
        emotion = EmotionDetectionResult(
            primary_emotion="neutral",
            confidence=0.7,
            scores={"neutral": 0.7},
            latency_ms=10.0,
        )
        safety = MagicMock(
            risk_level="none",
            response_policy="NORMAL_RAG",
        )

        with patch.object(settings, "LUNA_PROMPT_VERSION", "v1"):
            prompt = self.orchestrator._compose_system_prompt(
                emotion=emotion,
                safety_decision=safety,
                rag_items=[],
            )
            self.assertIn("Anda berbicara melalui ElevenLabs v4 Turbo", prompt)
            self.assertNotIn("[LAYER 1 — IDENTITAS & PERAN LUNA]", prompt)


if __name__ == "__main__":
    unittest.main()
