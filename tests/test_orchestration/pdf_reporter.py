import os
from datetime import datetime
from fpdf import FPDF


class OrchestrationReportPDF(FPDF):
    def header(self):
        self.set_font("Helvetica", "B", 14)
        self.set_text_color(30, 58, 138)  # Deep Navy Blue
        self.cell(0, 10, "Laporan Testing Orkestrasi - Luna AI", border=False, new_x="LMARGIN", new_y="NEXT", align="L")
        self.set_draw_color(226, 232, 240)
        self.set_line_width(0.5)
        self.line(10, self.get_y(), 200, self.get_y())
        self.ln(4)

    def footer(self):
        self.set_y(-15)
        self.set_font("Helvetica", "I", 8)
        self.set_text_color(148, 163, 184)
        self.cell(0, 10, f"Halaman {self.page_no()}/{{nb}} | Luna AI End-to-End Orchestration Suite", align="C")


def clean_text(text: str) -> str:
    """Clean string from characters not supported in standard FPDF Helvetica latin-1 font."""
    if not text:
        return ""
    # Map common unicode characters to ascii/latin-1 equivalents
    replacements = {
        "—": "-",
        "–": "-",
        "“": '"',
        "”": '"',
        "‘": "'",
        "’": "'",
        "…": "...",
        "\u200b": "",
    }
    for old, new in replacements.items():
        text = text.replace(old, new)
    # Encode with latin-1, replace unsupported characters with ?
    return text.encode("latin-1", "replace").decode("latin-1")


def generate_pdf_report(
    results: list[dict],
    summary_metrics: dict,
    output_path: str,
):
    """
    Generates a clean, modern PDF test report for Luna AI Orchestration.
    """
    pdf = OrchestrationReportPDF()
    pdf.alias_nb_pages()
    pdf.set_auto_page_break(auto=True, margin=15)
    pdf.add_page()

    # Title Banner
    pdf.set_font("Helvetica", "B", 18)
    pdf.set_text_color(15, 23, 42)
    pdf.cell(0, 10, clean_text("Laporan Testing Orkestrasi Luna AI"), new_x="LMARGIN", new_y="NEXT", align="L")
    
    pdf.set_font("Helvetica", "", 10)
    pdf.set_text_color(100, 116, 139)
    pdf.cell(0, 6, clean_text(f"Waktu Pengujian: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"), new_x="LMARGIN", new_y="NEXT", align="L")
    pdf.ln(4)

    # Executive Summary Box
    pdf.set_fill_color(248, 250, 252)
    pdf.set_draw_color(203, 213, 225)
    pdf.rect(10, pdf.get_y(), 190, 36, style="FD")
    
    start_y = pdf.get_y() + 4
    pdf.set_xy(14, start_y)
    pdf.set_font("Helvetica", "B", 11)
    pdf.set_text_color(30, 41, 59)
    pdf.cell(0, 6, clean_text("Ringkasan Metrik Pengujian"), new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(51, 65, 85)
    pdf.set_x(14)
    pdf.cell(90, 5, clean_text(f"* Total Audio Ditingkatkan/Diuji: {summary_metrics.get('total_files', 0)} Sampel"))
    pdf.cell(90, 5, clean_text(f"* LLM Provider Terkonfigurasi: {summary_metrics.get('llm_provider', 'N/A')} ({summary_metrics.get('llm_model', '')})"), new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_x(14)
    pdf.cell(90, 5, clean_text(f"* Rata-rata Latensi Emotion Detection: {summary_metrics.get('avg_emotion_latency', 0):.2f} ms"))
    pdf.cell(90, 5, clean_text(f"* Rata-rata Latensi RAG Search: {summary_metrics.get('avg_rag_latency', 0):.2f} ms"), new_x="LMARGIN", new_y="NEXT")

    pdf.set_x(14)
    pdf.cell(90, 5, clean_text(f"* Rata-rata Latensi Response LLM: {summary_metrics.get('avg_llm_latency', 0):.2f} ms"))
    pdf.cell(90, 5, clean_text(f"* Total Latensi Pipeline: {summary_metrics.get('avg_total_latency', 0):.2f} ms"), new_x="LMARGIN", new_y="NEXT")
    
    pdf.set_y(start_y + 36 + 6)

    # Summary Table
    pdf.set_font("Helvetica", "B", 12)
    pdf.set_text_color(30, 58, 138)
    pdf.cell(0, 8, clean_text("Tabel Ringkasan per File Audio"), new_x="LMARGIN", new_y="NEXT")

    # Table Header
    pdf.set_font("Helvetica", "B", 8)
    pdf.set_fill_color(226, 232, 240)
    pdf.set_text_color(30, 41, 59)
    pdf.cell(18, 7, clean_text("File"), border=1, fill=True, align="C")
    pdf.cell(65, 7, clean_text("Transkripsi (STT)"), border=1, fill=True, align="C")
    pdf.cell(32, 7, clean_text("Emosi (Score)"), border=1, fill=True, align="C")
    pdf.cell(25, 7, clean_text("Risk Level"), border=1, fill=True, align="C")
    pdf.cell(25, 7, clean_text("Latensi Total"), border=1, fill=True, align="C")
    pdf.cell(25, 7, clean_text("Status LLM"), border=1, fill=True, new_x="LMARGIN", new_y="NEXT", align="C")

    # Table Rows
    pdf.set_font("Helvetica", "", 8)
    pdf.set_text_color(51, 65, 85)
    for res in results:
        file_name = res.get("filename", "")
        stt_short = (res.get("stt_text", "")[:35] + "...") if len(res.get("stt_text", "")) > 35 else res.get("stt_text", "")
        emo_str = f"{res.get('emotion', 'N/A')} ({res.get('emotion_confidence', 0)*100:.0f}%)"
        risk_str = res.get("risk_level", "none").upper()
        latency_str = f"{res.get('total_latency_ms', 0):.0f} ms"
        status_llm = "SUCCESS" if res.get("llm_response") else "ERROR"

        pdf.cell(18, 6, clean_text(file_name), border=1, align="C")
        pdf.cell(65, 6, clean_text(stt_short), border=1)
        pdf.cell(32, 6, clean_text(emo_str), border=1, align="C")
        pdf.cell(25, 6, clean_text(risk_str), border=1, align="C")
        pdf.cell(25, 6, clean_text(latency_str), border=1, align="C")
        pdf.cell(25, 6, clean_text(status_llm), border=1, new_x="LMARGIN", new_y="NEXT", align="C")

    pdf.ln(8)

    # Detailed Analysis per Audio Sample
    pdf.set_font("Helvetica", "B", 14)
    pdf.set_text_color(30, 58, 138)
    pdf.cell(0, 10, clean_text("Detail Pengujian & Orkestrasi per Sampel Audio"), new_x="LMARGIN", new_y="NEXT")

    for idx, res in enumerate(results, 1):
        pdf.set_font("Helvetica", "B", 11)
        pdf.set_text_color(15, 23, 42)
        pdf.set_fill_color(241, 245, 249)
        pdf.cell(0, 7, clean_text(f"  {idx}. Sampel Audio: {res.get('filename')}"), border=1, fill=True, new_x="LMARGIN", new_y="NEXT")
        pdf.ln(2)

        # STT & Emotion Info
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(40, 5, clean_text("Transkripsi Teks (STT):"))
        pdf.set_font("Helvetica", "", 9)
        pdf.multi_cell(0, 5, clean_text(f'"{res.get("stt_text")}"'), new_x="LMARGIN", new_y="NEXT")

        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(40, 5, clean_text("Deteksi Emosi:"))
        pdf.set_font("Helvetica", "", 9)
        pdf.cell(0, 5, clean_text(f"{res.get('emotion')} (Confidence: {res.get('emotion_confidence',0)*100:.2f}%) | Latensi: {res.get('emotion_latency_ms',0):.2f} ms"), new_x="LMARGIN", new_y="NEXT")

        # Safety Gate
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(40, 5, clean_text("Safety Gate & Risk:"))
        pdf.set_font("Helvetica", "", 9)
        pdf.cell(0, 5, clean_text(f"Level: {res.get('risk_level').upper()} | Action Policy: {res.get('safety_policy')}"), new_x="LMARGIN", new_y="NEXT")

        # RAG Context Info
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(40, 5, clean_text("Konteks RAG (Qdrant):"))
        pdf.set_font("Helvetica", "", 9)
        rag_chunks = res.get("rag_context", [])
        if rag_chunks:
            pdf.cell(0, 5, clean_text(f"Berhasil menemukan {len(rag_chunks)} fragmen pengetahuan terdekat:"), new_x="LMARGIN", new_y="NEXT")
            for r_idx, chunk in enumerate(rag_chunks, 1):
                chunk_str = chunk.get("title", chunk.get("content", ""))[:80]
                pdf.set_x(15)
                pdf.cell(0, 4, clean_text(f"- [{r_idx}] {chunk_str}..."), new_x="LMARGIN", new_y="NEXT")
        else:
            pdf.cell(0, 5, clean_text("Tidak ada fragmen RAG khusus (General prompt used)."), new_x="LMARGIN", new_y="NEXT")

        # Prompt & Token Metrics
        pdf.ln(1)
        pdf.set_font("Helvetica", "B", 9)
        pdf.cell(40, 5, clean_text("Sistem Prompt LLM:"))
        pdf.set_font("Helvetica", "", 8)
        pdf.set_fill_color(248, 250, 252)
        sys_prompt = res.get("system_prompt", "")
        pdf.multi_cell(0, 4, clean_text(sys_prompt[:250] + ("..." if len(sys_prompt) > 250 else "")), border=1, fill=True, new_x="LMARGIN", new_y="NEXT")

        # Token usage if available
        tokens = res.get("token_usage", {})
        if tokens:
            pdf.set_font("Helvetica", "I", 8)
            pdf.cell(0, 4, clean_text(f"Token Usage: Prompt={tokens.get('prompt_tokens', 'N/A')}, Completion={tokens.get('completion_tokens', 'N/A')}, Total={tokens.get('total_tokens', 'N/A')}"), new_x="LMARGIN", new_y="NEXT")

        # LLM Response Output
        pdf.ln(1)
        pdf.set_font("Helvetica", "B", 9)
        pdf.set_text_color(16, 185, 129)  # Emerald Green
        pdf.cell(0, 5, clean_text(f"Respon AI ({summary_metrics.get('llm_provider')}):"), new_x="LMARGIN", new_y="NEXT")
        
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(15, 23, 42)
        pdf.set_fill_color(240, 253, 244)  # Light Green Tint
        pdf.set_draw_color(187, 247, 208)
        pdf.multi_cell(0, 5, clean_text(res.get("llm_response", "")), border=1, fill=True, new_x="LMARGIN", new_y="NEXT")
        
        pdf.ln(6)

    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    pdf.output(output_path)
    print(f"✅ PDF Report generated successfully at: {output_path}")
