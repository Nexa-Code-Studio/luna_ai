import re
import time
from collections.abc import AsyncGenerator
from dataclasses import dataclass

from packages.ai.utils.emotion_style_mapper import (
    has_recognized_audio_tag,
    is_recognized_audio_tag,
    sanitize_tts_audio_tags,
    strip_audio_tags,
)


@dataclass
class SpeechChunk:
    display_text: str
    tts_text: str
    delivery_style: str
    sequence: int
    is_first: bool = False
    is_final: bool = False


def _is_inside_bracket(text: str, max_bracket_len: int = 80) -> bool:
    """Check if the buffer currently contains an unclosed '[' within max_bracket_len characters."""
    last_open = text.rfind("[")
    if last_open == -1:
        return False
    last_close = text.rfind("]")
    if last_close > last_open:
        return False
    # If the unclosed bracket has grown excessively long, treat as plain text (safeguard)
    if len(text) - last_open > max_bracket_len:
        return False
    return True


class LatencyAwareSentenceChunker:
    """Buffers incoming LLM streaming tokens and yields semantically bounded SpeechChunks

    as early as possible to minimize time-to-first-audio while preserving natural prosody
    and ElevenLabs v4 Audio Tags.
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

        clean_display = strip_audio_tags(clean)
        # If there's no spoken text at all (e.g. only isolated tag) and not final, wait
        if not clean_display and not is_final:
            return None

        self.sequence += 1
        is_first = self.sequence == 1

        # Check if text already contains recognized inline Audio Tags
        has_tags = has_recognized_audio_tag(clean)

        # Only inject fallback audio_tag if first chunk, fallback tag is non-empty, and no inline tags exist
        if is_first and self.audio_tag and not has_tags:
            tts_text = f"{self.audio_tag} {clean}"
        else:
            tts_text = clean

        # Sanitize TTS text to eliminate any prohibited/theatrical tags
        tts_text = sanitize_tts_audio_tags(tts_text)

        # Extract primary delivery style if Audio Tag is present
        style = self.delivery_style
        if has_tags:
            tag_match = re.search(r"\[([a-zA-Z0-9_,\s\-\'\"]+)\]", clean)
            if tag_match and is_recognized_audio_tag(tag_match.group(1)):
                style = tag_match.group(1).strip()

        return SpeechChunk(
            display_text=clean_display,
            tts_text=tts_text,
            delivery_style=style,
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

            # Bracket protection: never split while inside [ ... ]
            in_bracket = _is_inside_bracket(self.buffer)

            # 1. Check for sentence end boundary (. ! ?)
            if not in_bracket and any(p in token for p in self.SENTENCE_END_PUNCTUATION):
                clean_display = strip_audio_tags(self.buffer)
                if len(clean_display) >= self.MIN_SENTENCE_CHARS:
                    chunk = self._create_chunk(self.buffer)
                    if chunk:
                        self.buffer = ""
                        self.last_emit_time = now
                        yield chunk
                    continue

            # 2. Check for clause boundary (, ; :) if buffer is getting long
            if not in_bracket and any(p in token for p in self.CLAUSE_END_PUNCTUATION):
                clean_display = strip_audio_tags(self.buffer)
                if len(clean_display) >= self.MIN_CLAUSE_CHARS:
                    chunk = self._create_chunk(self.buffer)
                    if chunk:
                        self.buffer = ""
                        self.last_emit_time = now
                        yield chunk
                    continue

            # 3. Latency timeout guard: if text is accumulating and time exceeded
            if not in_bracket and elapsed_ms >= self.MAX_TOKEN_WAIT_MS:
                clean_display = strip_audio_tags(self.buffer)
                if len(clean_display) >= self.MIN_SENTENCE_CHARS:
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
            if not in_bracket and len(self.buffer) >= self.MAX_BUFFER_CHARS:
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
