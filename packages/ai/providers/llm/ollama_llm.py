import json
import logging
from collections.abc import AsyncGenerator
from typing import Any

import httpx

from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.shared.config import settings

logger = logging.getLogger(__name__)


class OllamaLLMProvider(BaseLLMProvider):
    """Ollama LLM Provider supporting local or remote Ollama servers (e.g. qwen3:1.7B)."""

    def __init__(
        self,
        base_url: str | None = None,
        model: str | None = None,
    ) -> None:
        raw_url = base_url or settings.OLLAMA_BASE_URL or "http://localhost:11434"
        self.base_url = raw_url.rstrip("/")
        self.model = model or settings.OLLAMA_MODEL or "qwen3:1.7B"

    def _format_messages(self, messages: list[LLMMessage]) -> list[dict[str, str]]:
        return [{"role": m.role, "content": m.content} for m in messages]

    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        url = f"{self.base_url}/api/chat"
        payload = {
            "model": self.model,
            "messages": self._format_messages(messages),
            "stream": False,
            "options": {"temperature": temperature},
        }
        if response_format == "json":
            payload["format"] = "json"

        async with httpx.AsyncClient(timeout=60.0) as client:
            try:
                res = await client.post(url, json=payload)
                res.raise_for_status()
                data = res.json()
                return data.get("message", {}).get("content", "")
            except Exception as e:
                logger.error(f"OllamaLLMProvider error calling {url}: {e}")
                raise

    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        url = f"{self.base_url}/api/chat"
        payload = {
            "model": self.model,
            "messages": self._format_messages(messages),
            "stream": True,
            "options": {"temperature": temperature},
        }
        if response_format == "json":
            payload["format"] = "json"

        async with httpx.AsyncClient(timeout=60.0) as client:
            try:
                async with client.stream("POST", url, json=payload) as response:
                    response.raise_for_status()
                    async for line in response.aiter_lines():
                        if not line or not line.strip():
                            continue
                        try:
                            data = json.loads(line)
                            content = data.get("message", {}).get("content", "")
                            if content:
                                yield content
                        except json.JSONDecodeError:
                            continue
            except Exception as e:
                logger.error(f"OllamaLLMProvider streaming error calling {url}: {e}")
                raise
