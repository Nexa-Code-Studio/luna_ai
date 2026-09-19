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
