import asyncio
import json
from collections.abc import AsyncGenerator
from typing import Any

from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage


class MockLLMProvider(BaseLLMProvider):
    """Mock LLM Provider for local development & testing without external API keys."""

    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        last_user_msg = next((m.content for m in reversed(messages) if m.role == "user"), "")
        
        # If caller requested JSON output mode
        if response_format == "json" or (isinstance(response_format, dict) and response_format.get("type") == "json_object"):
            return json.dumps({
                "status": "success",
                "mock_mode": True,
                "input_received": last_user_msg,
                "ai_response": f"Mock LUNA response to: '{last_user_msg}'",
                "emotions": {"anxiety": 0.65, "calm": 0.35},
            }, ensure_ascii=False)

        return (
            f"[Mock LUNA AI Response] Terima kasih sudah bercerita: '{last_user_msg}'. "
            "Aku selalu ada di sini untuk mendengarkan dan mendukung perasaanmu."
        )

    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        full_text = await self.generate_response(
            messages, temperature=temperature, response_format=response_format, **kwargs
        )
        tokens = full_text.split(" ")
        for token in tokens:
            yield token + " "
            await asyncio.sleep(0.03)
