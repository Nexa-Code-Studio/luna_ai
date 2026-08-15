import pytest
from app.tasks.summarization import extract_memory_task, summarize_conversation_task


@pytest.mark.asyncio
async def test_summarize_conversation_task():
    res = await summarize_conversation_task({}, "conv_123")
    assert res["status"] == "completed"
    assert res["conversation_id"] == "conv_123"


@pytest.mark.asyncio
async def test_extract_memory_task():
    res = await extract_memory_task({}, "user_1", "User prefers concise answers")
    assert res["status"] == "completed"
    assert res["user_id"] == "user_1"
