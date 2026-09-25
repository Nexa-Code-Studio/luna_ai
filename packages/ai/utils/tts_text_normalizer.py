import re

# Pemetaan singkatan umum Bahasa Indonesia ke bentuk kata utuh untuk pelafalan TTS alami
INDONESIAN_ABBREVIATIONS: dict[str, str] = {
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
    r"\baja\b": "saja",
    r"\budah\b": "sudah",
    r"\bgak\b": "tidak",
    r"\bngga\b": "tidak",
    r"\bnggak\b": "tidak",
}

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


def sanitize_text_for_tts(text: str) -> str:
    """Membersihkan dan menormalkan teks Bahasa Indonesia untuk Text-to-Speech (ElevenLabs & Edge-TTS).
    
    Menjamin intonasi vokal alami, jeda pernapasan yang tepat pada titik dan koma,
    serta menghilangkan karakter markdown atau simbol yang dapat menimbulkan pelafalan aneh.
    """
    if not text:
        return ""

    cleaned = text

    # 0. Hapus explicit audio/emotion tag (misal [happily], [softly], [playful], dll.)
    # agar tidak tertinggal sebagai kata bahasa Inggris yang dibaca keras-keras oleh model vokal
    cleaned = re.sub(r"\[[a-zA-Z_\s]+\]\s*", "", cleaned)

    # 1. Hapus emoji
    cleaned = EMOJI_PATTERN.sub(" ", cleaned)

    # 2. Hapus format Markdown (*, **, _, __, #, ~, >, `)
    cleaned = re.sub(r"[*_~`#>]", " ", cleaned)

    # 3. Hapus bullet points di awal baris (- , + , • )
    cleaned = re.sub(r"(?:^|\n)\s*[-+•]\s*", " ", cleaned)

    # 4. Hapus nomor urut list di awal baris (misal '1. ', '2) ')
    cleaned = re.sub(r"(?:^|\n)\s*\d+[\.\)]\s*", " ", cleaned)

    # 5. Hilangkan kurung dan tanda kutip yang sering mengganggu prosodi
    cleaned = re.sub(r'[\(\)\[\]\{\}"\'“”‘’]', " ", cleaned)

    # 6. Ganti titik dua (:) dan titik koma (;) menjadi koma agar jeda intonasi lebih santun
    cleaned = re.sub(r"[:;]", ",", cleaned)

    # 7. Ganti garis pisah (-- atau -) yang berdiri sendiri menjadi koma
    cleaned = re.sub(r"\s+[-–—]+\s+", ", ", cleaned)

    # 8. Ekspansi singkatan percakapan Bahasa Indonesia
    for pattern, replacement in INDONESIAN_ABBREVIATIONS.items():
        cleaned = re.sub(pattern, replacement, cleaned, flags=re.IGNORECASE)

    # 9. Normalkan tanda baca berulang (misal '...', '???', '!!!', '?!')
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

    # 13. Normalkan multiple whitespace dan newline menjadi spasi tunggal
    cleaned = re.sub(r"\s+", " ", cleaned).strip()

    # 14. Pastikan teks berakhiran tanda baca akhir (. atau ? atau !) untuk nada penutup alami
    if cleaned and cleaned[-1] not in (".", "?", "!"):
        cleaned += "."

    return cleaned
