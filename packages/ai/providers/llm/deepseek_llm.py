from collections.abc import AsyncGenerator
import json
import logging
from typing import Any

import httpx

from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.shared.config import settings

logger = logging.getLogger(__name__)


def _clean_messages_for_llm(messages: list[LLMMessage]) -> list[dict[str, str]]:
    """Clean and structure messages so roles strictly alternate (system -> user -> assistant -> user)."""
    cleaned: list[dict[str, str]] = []
    for m in messages:
        if not m.content or not m.content.strip():
            continue
        role = m.role if m.role in ("system", "user", "assistant") else "user"
        # Merge consecutive messages with the same role (except system) to prevent HTTP 400 Bad Request
        if cleaned and cleaned[-1]["role"] == role and role != "system":
            cleaned[-1]["content"] += f"\n{m.content.strip()}"
        else:
            cleaned.append({"role": role, "content": m.content.strip()})
    return cleaned


class DeepSeekLLMProvider(BaseLLMProvider):
    """DeepSeek LLM Provider using DeepSeek API (deepseek-chat)."""

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or getattr(settings, "LLM_API_KEY", None)
        # Use explicit model or DEEPSEEK_MODEL or default to deepseek-chat (prevent inheriting OpenAI gpt-4o)
        configured_model = getattr(settings, "DEEPSEEK_MODEL", None) or getattr(settings, "LLM_MODEL", None)
        if not configured_model or configured_model.startswith("gpt-") or configured_model.startswith("gemini"):
            configured_model = "deepseek-chat"
        self.model = model or configured_model
        self.base_url = "https://api.deepseek.com/chat/completions"

    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        if not self.api_key:
            raise ValueError("DeepSeek API Key is missing. Check LLM_API_KEY in .env.")

        formatted_messages = _clean_messages_for_llm(messages)
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": formatted_messages,
            "temperature": temperature,
            "stream": False,
        }

        async with httpx.AsyncClient(timeout=30.0) as client:
            res = await client.post(self.base_url, headers=headers, json=payload)
            if res.status_code != 200:
                logger.error(f"❌ [DEEPSEEK API ERROR {res.status_code}]: {res.text}")
            res.raise_for_status()
            data = res.json()
            return data["choices"][0]["message"]["content"] or ""

    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        if not self.api_key:
            raise ValueError("DeepSeek API Key is missing. Check LLM_API_KEY in .env.")

        formatted_messages = _clean_messages_for_llm(messages)
        headers = {
            "Authorization": f"Bearer {self.api_key}",
            "Content-Type": "application/json",
        }
        payload = {
            "model": self.model,
            "messages": formatted_messages,
            "temperature": temperature,
            "stream": True,
        }

        async with httpx.AsyncClient(timeout=60.0) as client:
            async with client.stream("POST", self.base_url, headers=headers, json=payload) as response:
                if response.status_code != 200:
                    err_body = await response.aread()
                    logger.error(f"❌ [DEEPSEEK STREAM API ERROR {response.status_code}]: {err_body.decode('utf-8', errors='ignore')}")
                    response.raise_for_status()

                async for line in response.aiter_lines():
                    if line.startswith("data: "):
                        line_data = line[6:].strip()
                        if line_data == "[DONE]":
                            break
                        try:
                            chunk_json = json.loads(line_data)
                            delta = chunk_json.get("choices", [{}])[0].get("delta", {})
                            content = delta.get("content", "")
                            if content:
                                yield content
                        except json.JSONDecodeError:
                            continue
