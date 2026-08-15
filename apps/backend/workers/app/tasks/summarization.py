from typing import Any


async def summarize_conversation_task(ctx: dict[str, Any], conversation_id: str) -> dict[str, Any]:
    """Background task for generating conversation summaries."""
    # Placeholder for async LLM summarization pipeline
    return {
        "conversation_id": conversation_id,
        "summary": f"Summary for conversation {conversation_id}",
        "status": "completed",
    }


async def extract_memory_task(ctx: dict[str, Any], user_id: str, content: str) -> dict[str, Any]:
    """Background task for long-term memory extraction."""
    return {
        "user_id": user_id,
        "extracted_facts": [content],
        "status": "completed",
    }
