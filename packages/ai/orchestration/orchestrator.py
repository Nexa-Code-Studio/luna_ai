from collections.abc import AsyncGenerator
from typing import Any

from ai.interfaces.llm import BaseLLMProvider, LLMMessage
from ai.interfaces.stt import BaseSTTProvider
from ai.interfaces.tts import BaseTTSProvider


class AIOrchestrator:
    """Coordinates STT -> Context / RAG -> LLM -> TTS pipeline without coupling.

    Remains provider-agnostic.
    """

    def __init__(
        self,
        stt_provider: BaseSTTProvider | None = None,
        llm_provider: BaseLLMProvider | None = None,
        tts_provider: BaseTTSProvider | None = None,
    ):
        self.stt_provider = stt_provider
        self.llm_provider = llm_provider
        self.tts_provider = tts_provider

    async def process_turn(
        self,
        user_input: str | bytes,
        history: list[LLMMessage] | None = None,
        context: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        """Placeholder conceptual turn processor: STT -> Memory/Context -> LLM -> TTS."""
        # 1. STT if audio bytes provided
        text_input = user_input if isinstance(user_input, str) else "[Transcribed Text Placeholder]"

        # 2. Context / Safety / RAG retrieval placeholder
        # 3. LLM Response generation placeholder
        llm_output = f"Echo response to: {text_input}"

        return {
            "input_text": text_input,
            "response_text": llm_output,
            "audio_bytes": None,
            "context_used": context or {},
        }

    async def process_stream_turn(
        self,
        audio_stream: AsyncGenerator[bytes, None],
    ) -> AsyncGenerator[bytes, None]:
        """Placeholder streaming audio pipeline."""
        yield b""
