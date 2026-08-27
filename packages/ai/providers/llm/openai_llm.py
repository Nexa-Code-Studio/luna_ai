from collections.abc import AsyncGenerator
from typing import Any

from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.shared.config import settings


class OpenAILLMProvider(BaseLLMProvider):
    """OpenAI LLM Provider using GPT-4o."""

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or settings.LLM_API_KEY
        self.model = model or settings.LLM_MODEL or "gpt-4o"
        self._client = None
        if self.api_key:
            try:
                import openai
                self._client = openai.AsyncOpenAI(api_key=self.api_key)
            except ImportError:
                pass

    def _normalize_response_format(self, fmt: str | dict[str, Any] | None) -> dict[str, Any] | None:
        if fmt == "json":
            return {"type": "json_object"}
        if isinstance(fmt, dict):
            return fmt
        return None

    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        try:
            import openai
        except ImportError:
            raise ImportError("openai package is missing. Run pip install openai.")

        if not self.api_key:
            raise ValueError("OpenAI API Key is missing. Check LLM_API_KEY in .env.")

        if not self._client:
            self._client = openai.AsyncOpenAI(api_key=self.api_key)

        formatted_messages = [{"role": m.role, "content": m.content} for m in messages]
        extra_kwargs = dict(kwargs)
        norm_fmt = self._normalize_response_format(response_format)
        if norm_fmt:
            extra_kwargs["response_format"] = norm_fmt

        response = await self._client.chat.completions.create(
            model=self.model,
            messages=formatted_messages,  # type: ignore
            temperature=temperature,
            **extra_kwargs,
        )
        return response.choices[0].message.content or ""

    async def stream_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> AsyncGenerator[str, None]:
        try:
            import openai
        except ImportError:
            raise ImportError("openai package is missing. Run pip install openai.")

        if not self.api_key:
            raise ValueError("OpenAI API Key is missing. Check LLM_API_KEY in .env.")

        if not self._client:
            self._client = openai.AsyncOpenAI(api_key=self.api_key)

        formatted_messages = [{"role": m.role, "content": m.content} for m in messages]
        extra_kwargs = dict(kwargs)
        norm_fmt = self._normalize_response_format(response_format)
        if norm_fmt:
            extra_kwargs["response_format"] = norm_fmt

        stream = await self._client.chat.completions.create(
            model=self.model,
            messages=formatted_messages,  # type: ignore
            temperature=temperature,
            stream=True,
            **extra_kwargs,
        )
        async for chunk in stream:  # type: ignore
            content = chunk.choices[0].delta.content or ""
            if content:
                yield content
