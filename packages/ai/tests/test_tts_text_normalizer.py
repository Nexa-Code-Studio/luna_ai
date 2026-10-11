import pytest
from packages.ai.utils.tts_text_normalizer import sanitize_text_for_tts


def test_sanitize_markdown_and_emojis():
    raw = "**Halo Luna**! 😊 Aku merasa *sangat* lelah hari ini. #kesehatan"
    cleaned = sanitize_text_for_tts(raw)
    assert "**" not in cleaned
    assert "*" not in cleaned
    assert "#" not in cleaned
    assert "😊" not in cleaned
    assert "Halo Luna! Aku merasa sangat lelah hari ini. kesehatan." == cleaned


def test_sanitize_abbreviations():
    raw = "Kita perlu bicara dgn tenang, krn tsb penting utk sy dan km dll."
    cleaned = sanitize_text_for_tts(raw)
    assert "dengan" in cleaned
    assert "karena" in cleaned
    assert "tersebut" in cleaned
    assert "untuk" in cleaned
    assert "saya" in cleaned
    assert "kamu" in cleaned
    assert "dan lain-lain" in cleaned


def test_sanitize_punctuation_and_pauses():
    raw = "Tunggu dulu... Apakah kamu yakin?? Ya,tentu saja!!"
    cleaned = sanitize_text_for_tts(raw)
    assert "..." not in cleaned
    assert "??" not in cleaned
    assert "!!" not in cleaned
    assert "Tunggu dulu. Apakah kamu yakin? Ya, tentu saja!" == cleaned


def test_sanitize_empty_or_whitespace():
    assert sanitize_text_for_tts("") == ""
    assert sanitize_text_for_tts("   ") == ""


def test_sanitize_audio_tags():
    raw = "[happily] Halo Luna! Senang sekali bisa ngobrol lagi sama kamu."
    cleaned = sanitize_text_for_tts(raw)
    assert cleaned == "Halo Luna! Senang sekali bisa ngobrol lagi sama kamu."
    assert "happily" not in cleaned.lower()


def test_sanitize_preserve_audio_tags():
    raw = "[warm, calm] Terima kasih sudah cerita sejauh ini."
    cleaned = sanitize_text_for_tts(raw, preserve_audio_tags=True)
    assert "[warm, calm]" in cleaned
    assert "Terima kasih sudah cerita sejauh ini." in cleaned

    # Multi-tag preservation
    raw_multi = "[warm, calm] Terima kasih sudah cerita. [soft, reflective] Kedengarannya ini berat."
    cleaned_multi = sanitize_text_for_tts(raw_multi, preserve_audio_tags=True)
    assert "[warm, calm]" in cleaned_multi
    assert "[soft, reflective]" in cleaned_multi

    # Ellipsis preservation for ElevenLabs natural pause
    raw_ellipsis = "[gentle curiosity] Kalau boleh aku tanya... kapan kamu merasa tenang?"
    cleaned_ellipsis = sanitize_text_for_tts(raw_ellipsis, preserve_audio_tags=True)
    assert "[gentle curiosity]" in cleaned_ellipsis
    assert "..." in cleaned_ellipsis

    # Markdown and emojis stripped while tag survives
    raw_dirty = "[warm, calm] **Halo** Luna! 😊 Bagaimana harimu?"
    cleaned_dirty = sanitize_text_for_tts(raw_dirty, preserve_audio_tags=True)
    assert "[warm, calm]" in cleaned_dirty
    assert "**" not in cleaned_dirty
    assert "😊" not in cleaned_dirty
