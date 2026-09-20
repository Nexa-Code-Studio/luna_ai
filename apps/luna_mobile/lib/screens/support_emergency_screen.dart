import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

class SupportEmergencyScreen extends StatefulWidget {
  const SupportEmergencyScreen({super.key});

  /// Custom Route with smooth fade & gentle slide-up animation for enter and exit
  static Route<void> route() {
    return PageRouteBuilder<void>(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SupportEmergencyScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 250),
    );
  }

  @override
  State<SupportEmergencyScreen> createState() => _SupportEmergencyScreenState();
}

class _SupportEmergencyScreenState extends State<SupportEmergencyScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  late final AnimationController _contentFadeController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentOpacity;

  Map<String, dynamic>? _primaryContact;
  bool _isLoadingContact = true;

  static const String _dinkesWhatsappUrl =
      'https://api.whatsapp.com/send/?phone=6281380073120&text=halo%20kak%2C%20saya%20ingin%20bercerita%20mengenai...&type=phone_number&app_absent=0';

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchPrimaryEmergencyContact();
  }

  void _initAnimations() {
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOutCubic));
    _contentOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _contentFadeController, curve: Curves.easeOut));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine));

    _contentFadeController.forward();
  }

  @override
  void dispose() {
    _contentFadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _fetchPrimaryEmergencyContact() async {
    try {
      final token = await AppConfig.getToken();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/users/me/emergency-contacts'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && mounted) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final primary = data.firstWhere(
            (c) => c['is_primary'] == true,
            orElse: () => data.first,
          );
          setState(() {
            _primaryContact = primary as Map<String, dynamic>;
            _isLoadingContact = false;
          });
          return;
        }
      }
    } catch (_) {
      // Graceful fallback to default contacts
    }
    if (mounted) {
      setState(() {
        _isLoadingContact = false;
      });
    }
  }

  Future<void> _openDinkesHotline() async {
    final uri = Uri.parse(_dinkesWhatsappUrl);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak dapat membuka WhatsApp Dinkes'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  void _onTapHubungiOrangTerdekat() {
    if (_primaryContact != null && _primaryContact!['phone'] != null) {
      final phone = _primaryContact!['phone'].toString().replaceAll(RegExp(r'[^\d+]'), '');
      final uri = Uri.parse('tel:$phone');
      launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Navigator.pushNamed(context, '/emergency_contacts');
    }
  }

  void _openBreathingExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _BreathingExerciseModal(),
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

  Future<void> _handleDismiss() async {
    if (_contentFadeController.isAnimating) return;
    await _contentFadeController.reverse();
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final contactSubtitle = _isLoadingContact
        ? 'Memuat data kontak...'
        : (_primaryContact != null
            ? '${_primaryContact!['name']} (${_primaryContact!['relation']})'
            : 'Atur nomor kontak keluarga atau teman');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _handleDismiss();
        }
      },
      child: Scaffold(
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
            child: FadeTransition(
              opacity: _contentOpacity,
              child: SlideTransition(
                position: _contentSlide,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),

                      // Heart Badge Visual with Breathing Pulse Animation & Tap action
                      GestureDetector(
                        onTap: _openBreathingExercise,
                        child: AnimatedBuilder(
                          animation: _pulseScale,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseScale.value,
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
                      const SizedBox(height: 22),

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
                      const SizedBox(height: 24),

                      // Action Pill Card 1: WhatsApp Krisis Dinkes DKI
                      _buildSupportPillCard(
                        icon: Icons.support_agent_rounded,
                        iconBg: const Color(0xFFE8F8F5),
                        iconColor: const Color(0xFF00B894),
                        title: 'WhatsApp Krisis Dinkes DKI',
                        subtitle: 'Pendampingan Konseling Krisis Resmi',
                        onTap: _openDinkesHotline,
                      ),
                      const SizedBox(height: 12),

                      // Action Pill Card 2: Hubungi Orang Terdekat
                      _buildSupportPillCard(
                        icon: Icons.perm_contact_calendar_outlined,
                        iconBg: const Color(0xFFFFDCDD),
                        iconColor: const Color(0xFFE57373),
                        title: 'Hubungi Orang Terdekat',
                        subtitle: contactSubtitle,
                        onTap: _onTapHubungiOrangTerdekat,
                      ),
                      const SizedBox(height: 12),

                      // Action Pill Card 3: Hotline Krisis & Bantuan Darurat
                      _buildSupportPillCard(
                        icon: Icons.language,
                        iconBg: const Color(0xFFD7F3FF),
                        iconColor: const Color(0xFF00CEC9),
                        title: 'Hotline Krisis & Bantuan Darurat',
                        subtitle: 'SEJIWA 119, LISA, 112 Bebas Pulsa',
                        onTap: _openHotlineModal,
                      ),
                      const Spacer(flex: 2),

                      // 'Saya merasa lebih baik sekarang' Bottom Button
                      GestureDetector(
                        onTap: _handleDismiss,
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
    String? subtitle,
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
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 15,
              color: AppColors.textLight,
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

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


