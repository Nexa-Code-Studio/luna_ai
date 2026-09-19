import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class SupportEmergencyScreen extends StatefulWidget {
  const SupportEmergencyScreen({super.key});

  @override
  State<SupportEmergencyScreen> createState() => _SupportEmergencyScreenState();
}

class _SupportEmergencyScreenState extends State<SupportEmergencyScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _openBreathingExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BreathingExerciseModal(),
    );
  }

  void _openCounselorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _CounselorModal(),
    );
  }

  void _openHotlineModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _HotlineModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFFFF4F5),
              Color(0xFFFFE8EC),
              Color(0xFFFFF0F2),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Heart Badge Visual with Breathing Pulse Animation & Tap action
                GestureDetector(
                  onTap: _openBreathingExercise,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFE0E3),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE57373).withValues(alpha: 0.25),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite,
                        color: Color(0xFFE57373),
                        size: 40,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title & Subtitle
                Text(
                  'Tarik napas dalam-dalam.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "LUNA menyadari bahwa kamu mungkin membutuhkan dukungan ekstra saat ini. Kamu tidak harus menghadapi ini sendirian.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Quick breathing guide trigger button
                GestureDetector(
                  onTap: _openBreathingExercise,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE57373).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.air,
                          size: 16,
                          color: Color(0xFFE57373),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Mulai Latihan Napas 4-7-8',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFE57373),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Action Pill Card 1: Hubungi Orang Terpercaya
                _buildSupportPillCard(
                  icon: Icons.perm_contact_calendar_outlined,
                  iconBg: const Color(0xFFFFDCDD),
                  iconColor: const Color(0xFFE57373),
                  title: 'Hubungi Orang Terpercaya',
                  onTap: () {
                    Navigator.pushNamed(context, '/emergency_contacts');
                  },
                ),
                const SizedBox(height: 14),

                // Action Pill Card 2: Chat dengan Profesional
                _buildSupportPillCard(
                  icon: Icons.chat_bubble_outline,
                  iconBg: const Color(0xFFE4DCFF),
                  iconColor: const Color(0xFF6C5CE7),
                  title: 'Chat dengan Konselor Profesional',
                  onTap: _openCounselorModal,
                ),
                const SizedBox(height: 14),

                // Action Pill Card 3: Hotline Krisis
                _buildSupportPillCard(
                  icon: Icons.language,
                  iconBg: const Color(0xFFD7F3FF),
                  iconColor: const Color(0xFF00CEC9),
                  title: 'Hotline Krisis & Bantuan Darurat',
                  onTap: _openHotlineModal,
                ),
                const Spacer(flex: 2),

                // "Saya merasa lebih baik sekarang" Bottom Button
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: double.infinity,
                    height: 54,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFE57373).withValues(alpha: 0.4),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        "Saya merasa lebih baik sekarang",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSupportPillCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Interactive 4-7-8 Breathing Exercise Modal
// -----------------------------------------------------------------------------
class _BreathingExerciseModal extends StatefulWidget {
  const _BreathingExerciseModal();

  @override
  State<_BreathingExerciseModal> createState() => _BreathingExerciseModalState();
}

class _BreathingExerciseModalState extends State<_BreathingExerciseModal> {
  Timer? _timer;
  int _seconds = 0;
  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _seconds++;
      });
    });
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startTimer();
      } else {
        _timer?.cancel();
      }
    });
  }

  void _reset() {
    setState(() {
      _seconds = 0;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 4-7-8 Breathing Cycle (Total: 19 seconds per cycle)
    final cycle = _seconds % 19;
    String phaseText;
    String phaseDesc;
    Color phaseColor;
    double targetScale;

    if (cycle < 4) {
      phaseText = 'Tarik Napas';
      phaseDesc = 'Hirup napas perlahan melalui hidung (${4 - cycle}s)';
      phaseColor = const Color(0xFF6C5CE7);
      targetScale = 0.85 + (cycle / 4.0) * 0.35;
    } else if (cycle < 11) {
      final holdLeft = 11 - cycle;
      phaseText = 'Tahan Napas';
      phaseDesc = 'Tahan napas di dalam dada ($holdLeft s)';
      phaseColor = const Color(0xFFF59E0B);
      targetScale = 1.2;
    } else {
      final exhaleLeft = 19 - cycle;
      phaseText = 'Hembuskan Napas';
      phaseDesc = 'Lepaskan napas perlahan dari mulut ($exhaleLeft s)';
      phaseColor = const Color(0xFF00CEC9);
      targetScale = 1.2 - ((cycle - 11) / 8.0) * 0.35;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Latihan Napas 4-7-8',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Meredakan panik & menstabilkan detak jantung',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // Animated Breathing Circle
          SizedBox(
            height: 180,
            child: Center(
              child: AnimatedScale(
                scale: targetScale,
                duration: const Duration(seconds: 1),
                curve: Curves.easeInOut,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: phaseColor.withValues(alpha: 0.15),
                    border: Border.all(color: phaseColor, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: phaseColor.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.air, color: phaseColor, size: 30),
                        const SizedBox(height: 6),
                        Text(
                          phaseText,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: phaseColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Phase Description
          Text(
            phaseDesc,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 28),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: _reset,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Mulai Ulang'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _togglePlayPause,
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, size: 18),
                label: Text(_isPlaying ? 'Jeda' : 'Lanjutkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Counselor Options Modal
// -----------------------------------------------------------------------------
class _CounselorModal extends StatelessWidget {
  const _CounselorModal();

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Konseling & Dukungan',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Pilih jalur komunikasi yang paling membuatmu merasa aman.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          // Option 1: Chat dengan LUNA (Mode Krisis)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F0FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFD8B4FE)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF6C5CE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat dengan LUNA (24/7)',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Pendampingan de-eskalasi kecemasan instan',
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/chat');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C5CE7),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      'Buka Chat dengan LUNA Sekarang',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Option 2: LISA (Layanan Sahabat Jiwa)
          _buildContactRow(
            context,
            icon: Icons.support_agent,
            title: 'LISA - Hotline Pencegahan Krisis',
            subtitle: 'Layanan Sahabat Jiwa (WhatsApp & Call 24 Jam)',
            contactInfo: '0811-3855-472',
            onCopy: () => _copy(context, '0811-3855-472', 'Nomor LISA'),
          ),
          const SizedBox(height: 12),

          // Option 3: SEJIWA (Kemenkes)
          _buildContactRow(
            context,
            icon: Icons.local_hospital_outlined,
            title: 'Layanan SEJIWA (Kemenkes & BNPB)',
            subtitle: 'Konseling psikologis gratis dari pemerintah',
            contactInfo: '119 (Ekstensi 8)',
            onCopy: () => _copy(context, '119', 'Nomor SEJIWA (119 Ext 8)'),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildContactRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String contactInfo,
    required VoidCallback onCopy,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  contactInfo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
            tooltip: 'Salin nomor',
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Emergency Hotline Modal
// -----------------------------------------------------------------------------
class _HotlineModal extends StatelessWidget {
  const _HotlineModal();

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ($text) disalin ke clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotlines = [
      {
        'title': 'Layanan SEJIWA (Kemenkes)',
        'desc': 'Hotline kesehatan mental & pencegahan krisis',
        'number': '119',
        'display': '119 (Ext. 8)',
        'icon': Icons.health_and_safety_outlined,
      },
      {
        'title': 'LISA - Sahabat Jiwa',
        'desc': 'Bantuan darurat kesehatan mental 24 Jam',
        'number': '08113855472',
        'display': '0811-3855-472',
        'icon': Icons.phone_in_talk_outlined,
      },
      {
        'title': 'Nomor Darurat Nasional',
        'desc': 'Panggilan darurat terpadu bebas pulsa',
        'number': '112',
        'display': '112',
        'icon': Icons.emergency_outlined,
      },
      {
        'title': 'Ambulans Kedaruratan Medis',
        'desc': 'Layanan tanggap darurat medis cepat',
        'number': '118',
        'display': '118 / 119',
        'icon': Icons.local_hospital_outlined,
      },
      {
        'title': 'Kepolisian Republik Indonesia',
        'desc': 'Kedaruratan keamanan & keselamatan jiwa',
        'number': '110',
        'display': '110',
        'icon': Icons.local_police_outlined,
      },
      {
        'title': 'Halo Kemenkes',
        'desc': 'Informasi fasilitas layanan kesehatan resmi',
        'number': '1500567',
        'display': '1500-567',
        'icon': Icons.info_outline,
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Hotline Krisis & Darurat',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Tekan ikon salin untuk menyalin nomor langsung ke dialer telepon.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),

          // List
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: hotlines.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final h = hotlines[i];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD7F3FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          h['icon'] as IconData,
                          color: const Color(0xFF00CEC9),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              h['title'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              h['desc'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              h['display'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF00838F),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        tooltip: 'Salin nomor',
                        onPressed: () => _copy(
                          context,
                          h['number'] as String,
                          h['title'] as String,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


