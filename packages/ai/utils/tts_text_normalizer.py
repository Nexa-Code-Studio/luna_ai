import re

# Singkatan ketikan teks (chat abbreviations) yang perlu diekspansi untuk pelafalan TTS alami
INDONESIAN_CHAT_ABBREVIATIONS: dict[str, str] = {
    r"\bdll\b\.?": "dan lain-lain",
    r"\bdsb\b\.?": "dan sebagainya",
    r"\bdst\b\.?": "dan seterusnya",
    r"\byg\b": "yang",
    r"\bdgn\b": "dengan",
    r"\bkpd\b": "kepada",
    r"\bdr\b": "dari",
    r"\bsbg\b": "sebagai",
    r"\bkrn\b": "karena",
    r"\butk\b": "untuk",
    r"\btsb\b\.?": "tersebut",
    r"\bbgt\b": "banget",
    r"\borg\b": "orang",
    r"\bsy\b": "saya",
    r"\bkm\b": "kamu",
    r"\bjg\b": "juga",
}

# Formalisasi ketat baku (hanya aktif jika mode 'strict' diaktifkan secara eksplisit)
INDONESIAN_STRICT_FORMALIZATIONS: dict[str, str] = {
    r"\baja\b": "saja",
    r"\budah\b": "sudah",
    r"\bgak\b": "tidak",
    r"\bngga\b": "tidak",
    r"\bnggak\b": "tidak",
}

INDONESIAN_ABBREVIATIONS = INDONESIAN_CHAT_ABBREVIATIONS

# Regex untuk mendeteksi karakter emoji dan simbol grafis Unicode
EMOJI_PATTERN = re.compile(
    "["
    "\U0001F600-\U0001F64F"  # Emoticons
    "\U0001F300-\U0001F5FF"  # Symbols & pictographs
    "\U0001F680-\U0001F6FF"  # Transport & map
    "\U0001F1E0-\U0001F1FF"  # Flags
    "\U0001F900-\U0001F9FF"  # Supplemental symbols
    "\U0001FA00-\U0001FA6F"  # Chess symbols
    "\U0001FA70-\U0001FAFF"  # Symbols and pictographs extended-a
    "\U00002702-\U000027B0"  # Dingbats
    "\U000024C2-\U0001F251"
    "]+",
    flags=re.UNICODE,
)


AUDIO_TAG_PATTERN = re.compile(r"\[([a-zA-Z][a-zA-Z0-9_,\s\-\'\"]*)\]")


def sanitize_text_for_tts(
    text: str,
    preserve_audio_tags: bool = False,
    normalizer_mode: str | None = None,
) -> str:
    """Membersihkan dan menormalkan teks Bahasa Indonesia untuk Text-to-Speech (ElevenLabs & Edge-TTS).
    
    Jika preserve_audio_tags=True:
    Audio tags resmi ElevenLabs (seperti [warm, calm], [thoughtful], [softly]) dipertahankan
    untuk mengontrol gaya bicara dan emosi pada ElevenLabs v4 Turbo.
    Tanda jeda elipsis (...) juga dipertahankan untuk jeda bicara alami.
    """
    if not text:
        return ""

    cleaned = text
    saved_tags: list[str] = []

    if preserve_audio_tags:
        # Mask valid audio tags before normalization
        def _mask_tag(m: re.Match[str]) -> str:
            tag_content = m.group(1).strip()
            if len(tag_content) >= 2 and not tag_content.isdigit():
                placeholder = f"LUNATTSTAG{len(saved_tags)}ENDTAG"
                saved_tags.append(f"[{tag_content}]")
                return f" {placeholder} "
            return m.group(0)

        cleaned = AUDIO_TAG_PATTERN.sub(_mask_tag, cleaned)
        # Protect ellipses (...) from being collapsed to a single period
        cleaned = re.sub(r"\.{3,}", " LUNATTSELLIPSIS ", cleaned)
    else:
        # Strip all explicit audio/emotion tags if not preserving
        cleaned = AUDIO_TAG_PATTERN.sub(" ", cleaned)

    # 1. Hapus emoji
    cleaned = EMOJI_PATTERN.sub(" ", cleaned)

    # 2. Hapus format Markdown (*, **, _, __, #, ~, >, `)
    cleaned = re.sub(r"[*_~`#>]", " ", cleaned)

    # 3. Hapus bullet points di awal baris (- , + , • )
    cleaned = re.sub(r"(?:^|\n)\s*[-+•]\s*", " ", cleaned)

    # 4. Hapus nomor urut list di awal baris (misal '1. ', '2) ')
    cleaned = re.sub(r"(?:^|\n)\s*\d+[\.\)]\s*", " ", cleaned)

    # 5. Hilangkan kurung dan tanda kutip yang sering mengganggu prosodi
    # (Placeholder LUNATTSTAGXENDTAG aman karena hanya alfanumerik)
    cleaned = re.sub(r'[\(\)\[\]\{\}"\'“”‘’]', " ", cleaned)

    # 6. Ganti titik dua (:) dan titik koma (;) menjadi koma agar jeda intonasi lebih santun
    cleaned = re.sub(r"[:;]", ",", cleaned)

    # 7. Ganti garis pisah (-- atau -) yang berdiri sendiri menjadi koma
    cleaned = re.sub(r"\s+[-–—]+\s+", ", ", cleaned)

    # 8. Ekspansi singkatan percakapan Bahasa Indonesia
    from packages.shared.config import settings
    active_mode = normalizer_mode or getattr(settings, "LUNA_NORMALIZER_MODE", "conversational")

    for pattern, replacement in INDONESIAN_CHAT_ABBREVIATIONS.items():
        cleaned = re.sub(pattern, replacement, cleaned, flags=re.IGNORECASE)

    if active_mode == "strict":
        for pattern, replacement in INDONESIAN_STRICT_FORMALIZATIONS.items():
            cleaned = re.sub(pattern, replacement, cleaned, flags=re.IGNORECASE)

    # 9. Normalkan tanda baca berulang (misal '???', '!!!', '?!')
    cleaned = re.sub(r"\.{2,}", ".", cleaned)
    cleaned = re.sub(r"\?{2,}", "?", cleaned)
    cleaned = re.sub(r"!{2,}", "!", cleaned)
    cleaned = re.sub(r"[?!]{2,}", "?", cleaned)
    cleaned = re.sub(r",{2,}", ",", cleaned)

    # 10. Pastikan tidak ada spasi sebelum tanda baca
    cleaned = re.sub(r"\s+([,.!?])", r"\1", cleaned)

    # 11. Pastikan setiap koma diikuti tepat satu spasi
    cleaned = re.sub(r",(?!\s)", ", ", cleaned)

    # 12. Pastikan setiap titik/tanya/seru diikuti tepat satu spasi jika masih ada kata setelahnya
    cleaned = re.sub(r"([.!?])([A-Za-z0-9])", r"\1 \2", cleaned)

    # Kembalikan elipsis dan audio tags
    if preserve_audio_tags:
        cleaned = cleaned.replace("LUNATTSELLIPSIS", "...")
        for idx, tag in enumerate(saved_tags):
            placeholder = f"LUNATTSTAG{idx}ENDTAG"
            cleaned = cleaned.replace(placeholder, tag)

    # 13. Normalkan multiple whitespace dan newline menjadi spasi tunggal
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    # 14. Pastikan tag diikuti oleh spasi jika menempel pada kata berikutnya (e.g. "[warm, calm]Halo" -> "[warm, calm] Halo")
    cleaned = re.sub(r"(\])([A-Za-z0-9])", r"\1 \2", cleaned)

    # 15. Pastikan teks berakhiran tanda baca akhir (. atau ? atau ! atau ...) untuk nada penutup alami
    if cleaned and not cleaned.endswith((".", "?", "!", "...")):
        cleaned += "."

    return cleaned
