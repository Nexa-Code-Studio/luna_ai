from collections.abc import AsyncGenerator
from dataclasses import dataclass
import time


@dataclass
class SpeechChunk:
    display_text: str
    tts_text: str
    delivery_style: str
    sequence: int
    is_first: bool = False
    is_final: bool = False


class LatencyAwareSentenceChunker:
    """Buffers incoming LLM streaming tokens and yields semantically bounded SpeechChunks

    as early as possible to minimize time-to-first-audio while preserving natural prosody.
    """

    # Boundaries
    SENTENCE_END_PUNCTUATION = {".", "!", "?"}
    CLAUSE_END_PUNCTUATION = {",", ";", ":", "—", "–"}

    # Tuning constants
    MIN_SENTENCE_CHARS: int = 25  # Minimum characters before breaking at sentence punctuation
    MIN_CLAUSE_CHARS: int = 55    # Minimum characters before breaking at clause punctuation
    MAX_BUFFER_CHARS: int = 140   # Hard maximum buffer size to prevent excessive speech chunk delay
    MAX_TOKEN_WAIT_MS: float = 650.0  # Flush buffer if no punctuation occurs within this window

    def __init__(self, delivery_style: str = "neutral", audio_tag: str = "") -> None:
        self.delivery_style = delivery_style
        self.audio_tag = audio_tag.strip()
        self.buffer = ""
        self.sequence = 0
        self.last_emit_time = time.monotonic()

    def _create_chunk(self, raw_text: str, is_final: bool = False) -> SpeechChunk | None:
        clean = raw_text.strip()
        if not clean:
            return None

        self.sequence += 1
        is_first = self.sequence == 1

        # Only inject the Audio Tag on the very first chunk of the turn
        if is_first and self.audio_tag:
            tts_text = f"{self.audio_tag} {clean}"
        else:
            tts_text = clean

        return SpeechChunk(
            display_text=clean,
            tts_text=tts_text,
            delivery_style=self.delivery_style,
            sequence=self.sequence,
            is_first=is_first,
            is_final=is_final,
        )

    async def chunk_stream(
        self, token_stream: AsyncGenerator[str, None]
    ) -> AsyncGenerator[SpeechChunk, None]:
        """Process an asynchronous token stream and yield SpeechChunks incrementally."""
        self.buffer = ""
        self.sequence = 0
        self.last_emit_time = time.monotonic()

        async for token in token_stream:
            self.buffer += token
            now = time.monotonic()
            elapsed_ms = (now - self.last_emit_time) * 1000.0

            # 1. Check for sentence end boundary (. ! ?)
            last_char = token.strip()[-1:] if token.strip() else ""
            if any(p in token for p in self.SENTENCE_END_PUNCTUATION):
                # Ensure we have minimum context so we don't break on abbreviations e.g. "dr."
                if len(self.buffer.strip()) >= self.MIN_SENTENCE_CHARS:
                    chunk = self._create_chunk(self.buffer)
                    if chunk:
                        self.buffer = ""
                        self.last_emit_time = now
                        yield chunk
                    continue

            # 2. Check for clause boundary (, ; :) if buffer is getting long
            if any(p in token for p in self.CLAUSE_END_PUNCTUATION):
                if len(self.buffer.strip()) >= self.MIN_CLAUSE_CHARS:
                    chunk = self._create_chunk(self.buffer)
                    if chunk:
                        self.buffer = ""
                        self.last_emit_time = now
                        yield chunk
                    continue

            # 3. Latency timeout guard: if text is accumulating and time exceeded
            if elapsed_ms >= self.MAX_TOKEN_WAIT_MS and len(self.buffer.strip()) >= self.MIN_SENTENCE_CHARS:
                # Break strictly at the last whitespace so we never split words in half
                buf_strip = self.buffer.strip()
                last_space = buf_strip.rfind(" ")
                if last_space > 0:
                    to_emit = buf_strip[:last_space]
                    self.buffer = buf_strip[last_space:].lstrip()
                    chunk = self._create_chunk(to_emit)
                    if chunk:
                        self.last_emit_time = now
                        yield chunk
                continue

            # 4. Hard maximum buffer safeguard
            if len(self.buffer) >= self.MAX_BUFFER_CHARS:
                buf_strip = self.buffer.strip()
                last_space = buf_strip.rfind(" ")
                if last_space > 0:
                    to_emit = buf_strip[:last_space]
                    self.buffer = buf_strip[last_space:].lstrip()
                else:
                    to_emit = buf_strip
                    self.buffer = ""

                chunk = self._create_chunk(to_emit)
                if chunk:
                    self.last_emit_time = now
                    yield chunk

        # End of stream flush
        if self.buffer.strip():
            chunk = self._create_chunk(self.buffer, is_final=True)
            self.buffer = ""
            if chunk:
                yield chunk
