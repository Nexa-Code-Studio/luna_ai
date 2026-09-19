import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../widgets/glass_card.dart';

class TermsDisclaimerScreen extends StatelessWidget {
  const TermsDisclaimerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF3F5FF),
              Color(0xFFE9ECFF),
              Color(0xFFF8F9FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom Header Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.textPrimary, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Syarat & Disclaimer Etika',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Main Content ScrollView
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    children: [
                      // Header Card
                      GlassCard(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.gavel_rounded,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Luna AI Ethics & Terms',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Panduan Etika, Batasan Medis & Kebijakan Layanan',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section 1: Prinsip Etika Layanan
                      _buildSectionCard(
                        icon: Icons.favorite_border_rounded,
                        iconColor: const Color(0xFF6C5CE7),
                        title: '1. Prinsip Etika Konseling AI',
                        content: [
                          'Non-Judgmental Space: Luna AI dirancang untuk menyediakan ruang refleksi emosional yang aman tanpa penilaian moral atau preskriptif.',
                          'Empati CBT Ringan: Bahasa interaksi mengadopsi pendekatan Cognitive Behavioral Therapy (CBT) ringan untuk membantu pengguna memvalidasi emosi secara sehat.',
                          'Aksesibilitas 24/7: Layanan ini beroperasi 24 jam sehari untuk mendampingi kesehatan mental harian pengguna.',
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 2: Batasan Wewenang Medis (Medical Disclaimer)
                      _buildSectionCard(
                        icon: Icons.health_and_safety_outlined,
                        iconColor: const Color(0xFFD32F2F),
                        title: '2. Batasan Wewenang Medis (Medical Disclaimer)',
                        content: [
                          'Bukan Tenaga Medis Berlisensi: Luna AI adalah sistem pendukung berbasis kecerdasan buatan, BUKAN psikolog klinis, psikiater, atau fasilitas kesehatan manusia.',
                          'Tidak Berwewenang Memberikan Diagnosis: Luna AI TIDAK memberikan diagnosis klinis resmi (seperti Depresi Klinis, Bipolar, Skizofrenia, atau Gangguan Kecemasan Akut).',
                          'Tanpa Resep Obat: Luna AI TIDAK BERWEWENANG mengeluarakan atau menyarankan resep obat-obatan psikiatri/medikal.',
                          'Pengganti Terapi Nyata: Layanan ini tidak dimaksudkan untuk menggantikan sesi terapi langsung dengan profesional kesehatan mental berlisensi.',
                        ],
                        highlightColor: const Color(0xFFFFF5F5),
                      ),
                      const SizedBox(height: 16),

                      // Section 3: Protokol Keselamatan & Penanganan Krisis
                      _buildSectionCard(
                        icon: Icons.shield_outlined,
                        iconColor: const Color(0xFFE67E22),
                        title: '3. Protokol Keselamatan Emosional & Krisis',
                        content: [
                          'Multi-layered Safety Gate: Sistem memindai pesan secara real-time untuk mendeteksi indikasi risiko krisis emosional atau kecenderungan mencederai diri (Self-Harm / Suicidal Ideation).',
                          'Eskalasi Krisis Otomatis: Apabila terdeteksi indikasi krisis tinggi (High Risk), sesi konseling standar akan dihentikan dan sistem secara otomatis memicu halaman penanganan krisis darurat.',
                          'Kontak Darurat & Hotline: Pengguna akan diarahkan ke Hotline Kesehatan Mental Resmi (Layanan Sejiwa 119 ext 8) serta opsi untuk menghubungkan Kontak Darurat Utama.',
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Section 4: Kebijakan Privasi & Etika Penggunaan
                      _buildSectionCard(
                        icon: Icons.lock_outline_rounded,
                        iconColor: const Color(0xFF00B894),
                        title: '4. Kerahasiaan Data & Etika Penggunaan',
                        content: [
                          'Kerahasiaan Percakapan: Data sesi percakapan dan jurnal Anda dilindungi dan tidak dijual atau dibagikan kepada pihak ketiga non-medis tanpa persetujuan Anda.',
                          'Tata Tertib Penggunaan: Pengguna dilarang memanfaatkan AI untuk mempromosikan tindakan ilegal, membahayakan orang lain, atau melakukan peretasan prompt (jailbreaking).',
                          'Sintesis Jurnal Otomatis: Ringkasan emosional dibuat otomatis untuk membantu pengguna memantau perkembangan kesejahteraan mental secara mandiri.',
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Footer Statement
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Text(
                          'Dengan menggunakan aplikasi Luna, Anda menyatakan telah membaca, memahami, dan menyetujui seluruh ketentuan etika dan batasan layanan di atas.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required List<String> content,
    Color? highlightColor,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 12),
          ...content.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
