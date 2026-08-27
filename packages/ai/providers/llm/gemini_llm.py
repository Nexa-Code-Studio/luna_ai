import asyncio
from collections.abc import AsyncGenerator
from typing import Any

from packages.ai.interfaces.llm import BaseLLMProvider, LLMMessage
from packages.shared.config import settings


class GeminiLLMProvider(BaseLLMProvider):
    """Google Gemini LLM Provider."""

    def __init__(self, api_key: str | None = None, model: str | None = None) -> None:
        self.api_key = api_key or settings.GEMINI_API_KEY or settings.LLM_API_KEY
        self.model_name = model or settings.GEMINI_MODEL or "gemini-1.5-flash"

    async def generate_response(
        self,
        messages: list[LLMMessage],
        temperature: float = 0.7,
        response_format: str | dict[str, Any] | None = None,
        **kwargs: Any,
    ) -> str:
        if not self.api_key:
            raise ValueError("Gemini API Key is missing. Check GEMINI_API_KEY or LLM_API_KEY in .env.")

        try:
            import google.generativeai as genai

            genai.configure(api_key=self.api_key)
            
            gen_config: dict[str, Any] = {"temperature": temperature}
            if response_format == "json":
                gen_config["response_mime_type"] = "application/json"

            model = genai.GenerativeModel(self.model_name)
            prompt = "\n".join([f"{m.role.capitalize()}: {m.content}" for m in messages])
            response = await asyncio.to_thread(
                model.generate_content,
                prompt,
                generation_config=gen_config,
            )
            return response.text
        except ImportError:
            raise ImportError("google-generativeai package is missing. Run pip install google-generativeai.")

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
