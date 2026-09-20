import json
import pytest
from ai.interfaces.llm import BaseLLMProvider, LLMMessage
from ai.services.dass_extraction_service import DASSExtractionService


class MockExtractionLLMProvider(BaseLLMProvider):
    async def generate_response(self, messages: list[LLMMessage], **kwargs) -> str:
        return ""

    async def stream_response(self, messages: list[LLMMessage], **kwargs):
        mock_output = [
            {
                "item_id": 1,
                "scale": "stress",
                "question_text": "Saya merasa sulit untuk beristirahat atau menenangkan diri",
                "score": 2,
                "evidence": "Gue pusing banget dan gak bisa tenang mikirin kerjaan",
                "reason": "Pengguna mengekspresikan ketegangan pikiran yang menghambat relaksasi.",
                "confidence": 0.90,
                "is_user_edited": False,
            },
            {
                "item_id": 13,
                "scale": "depression",
                "question_text": "Saya merasa sedih, murung, dan tertekan",
                "score": 3,
                "evidence": "Aku merasa sedih dan hampa seharian",
                "reason": "Pengguna merasa hampa dan sedih terus menerus sepanjang hari.",
                "confidence": 0.95,
                "is_user_edited": False,
            },
        ]
        chunk = json.dumps(mock_output)
        yield chunk


@pytest.mark.asyncio
async def test_dass_extraction_from_transcript():
    mock_llm = MockExtractionLLMProvider()
    service = DASSExtractionService(llm_provider=mock_llm)

    transcript = "USER: Gue pusing banget dan gak bisa tenang mikirin kerjaan. Aku merasa sedih dan hampa seharian."
    items = await service.extract_from_transcript(transcript)

    assert len(items) == 21
    item_1 = next(it for it in items if it["item_id"] == 1)
    assert item_1["score"] == 2
    assert "pusing banget" in item_1["evidence"]
    assert item_1["reason"] is not None
    assert item_1["confidence"] == 0.90

    item_13 = next(it for it in items if it["item_id"] == 13)
    assert item_13["score"] == 3
    assert item_13["scale"] == "depression"
    assert item_13["reason"] is not None

    # Butir yang tidak terindikasi harus bernilai 0
    item_2 = next(it for it in items if it["item_id"] == 2)
    assert item_2["score"] == 0
    assert item_2["evidence"] is None
    assert item_2["reason"] is None


@pytest.mark.asyncio
async def test_dass_extraction_empty_transcript():
    service = DASSExtractionService(llm_provider=MockExtractionLLMProvider())
    items = await service.extract_from_transcript("")

    assert len(items) == 21
    for it in items:
        assert it["score"] == 0
        assert it["evidence"] is None
