import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import '../theme/app_colors.dart';

class SupportEmergencyScreen extends StatefulWidget {
  const SupportEmergencyScreen({super.key});

  /// Custom Route with smooth fade & gentle slide-up animation for enter and exit
  static Route<void> route() {
    return PageRouteBuilder(
      settings: const RouteSettings(name: '/support'),
      pageBuilder: (context, animation, secondaryAnimation) => const SupportEmergencyScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.08),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 550),
      reverseTransitionDuration: const Duration(milliseconds: 400),
    );
  }

  @override
  State<SupportEmergencyScreen> createState() => _SupportEmergencyScreenState();
}

class _SupportEmergencyScreenState extends State<SupportEmergencyScreen>
    with TickerProviderStateMixin {
  static const String _dinkesWhatsappUrl =
      'https://api.whatsapp.com/send/?phone=6281380073120&text=halo%20kak%2C%20saya%20ingin%20bercerita%20mengenai...&type=phone_number&app_absent=0';

  Map<String, dynamic>? _primaryContact;
  bool _isLoadingContact = true;

  late final AnimationController _contentFadeController;
  late final Animation<double> _contentOpacity;
  late final Animation<Offset> _contentSlide;

  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _fetchPrimaryEmergencyContact();
  }

  void _initAnimations() {
    // Internal Staggered Content Animation
    _contentFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentOpacity = CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOut,
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentFadeController,
      curve: Curves.easeOutCubic,
    ));
    _contentFadeController.forward();

    // Subtle breathing pulse for calming effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseScale = Tween<double>(begin: 1.0, end: 1.07).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _contentFadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _contentFadeController.reverse();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _fetchPrimaryEmergencyContact() async {
    try {
      final headers = await AppConfig.getAuthHeaders();
      final res = await http
          .get(
            Uri.parse('${AppConfig.baseUrl}/users/emergency-contacts'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 4));

      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body);
        if (data is List && data.isNotEmpty) {
          final primary = data.firstWhere(
            (c) => c['is_primary'] == true || c['isPrimary'] == true,
            orElse: () => data.first,
          );
          setState(() {
            _primaryContact = {
              'id': primary['id']?.toString() ?? '',
              'name': primary['name']?.toString() ?? 'Kerabat Terdekat',
              'relation': (primary['relationship'] ?? primary['relation'])?.toString() ?? 'Orang Terdekat',
              'phone': (primary['phone'] ?? primary['phone_number'])?.toString() ?? '',
            };
            _isLoadingContact = false;
          });
          return;
        }
      }
    } catch (_) {}

    // Fallback default mock jika gagal memuat atau belum tersimpan
    if (mounted) {
      setState(() {
        if (AppConfig.useMockData) {
          _primaryContact = {
            'id': 'mock_1',
            'name': 'Ibu',
            'relation': 'Keluarga',
            'phone': '+62 812-3456-7890',
          };
        } else {
          _primaryContact = null;
        }
        _isLoadingContact = false;
      });
    }
  }

  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(uri);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tidak dapat membuka tautan: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _openDinkesHotline() {
    _launchExternalUrl(_dinkesWhatsappUrl);
  }

  String _formatPhoneForWhatsapp(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '62${cleaned.substring(1)}';
    }
    return cleaned;
  }

  void _onTapHubungiOrangTerdekat() {
    if (_primaryContact == null || (_primaryContact!['phone'] as String).trim().isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFE57373)),
              SizedBox(width: 8),
              Text('Kontak Belum Tersedia'),
            ],
          ),
          content: const Text(
            'Kamu belum mendaftarkan nomor telepon orang terdekat. Tambahkan kontak darurat sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE57373)),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, '/emergency_contacts').then((_) {
                  _fetchPrimaryEmergencyContact();
                });
              },
              child: const Text('Tambah Kontak', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      return;
    }

    final name = _primaryContact!['name'] ?? 'Orang Terdekat';
    final relation = _primaryContact!['relation'] ?? '';
    final rawPhone = _primaryContact!['phone'] ?? '';
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    final waPhone = _formatPhoneForWhatsapp(rawPhone);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Hubungi $name',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$relation • $rawPhone',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            // Panggilan Telepon
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternalUrl('tel:$cleanPhone');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFFDCDD)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFE57373),
                      ),
                      child: const Icon(Icons.phone, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Panggilan Telepon Langsung',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Hubungi melalui nomor seluler',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Kirim Pesan WhatsApp
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.pop(ctx);
                _launchExternalUrl('https://wa.me/$waPhone');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F8F5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFB2EBF2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF00B894),
                      ),
                      child: const Icon(Icons.chat_bubble, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kirim Pesan WhatsApp',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Mulai percakapan secara leluasa',
                            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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

                      // Heart Badge Visual with subtle breathing pulse
                      AnimatedBuilder(
                        animation: _pulseScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseScale.value,
                            child: child,
                          );
                        },
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFE0E3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFE57373).withValues(alpha: 0.25),
                                blurRadius: 32,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Color(0xFFE57373),
                            size: 42,
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

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
                      const SizedBox(height: 12),
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
                      const SizedBox(height: 36),

                      // Action Card 1: Hubungi Orang Terpercaya
                      _buildSupportPillCard(
                        icon: Icons.favorite_border_rounded,
                        iconBg: const Color(0xFFFFDCDD),
                        iconColor: const Color(0xFFE57373),
                        title: 'Hubungi Orang Terdekat',
                        subtitle: contactSubtitle,
                        onTap: _onTapHubungiOrangTerdekat,
                      ),
                      const SizedBox(height: 14),

                      // Action Card 2: Hotline Dinas Kesehatan
                      _buildSupportPillCard(
                        icon: Icons.support_agent_rounded,
                        iconBg: const Color(0xFFE8F8F5),
                        iconColor: const Color(0xFF00B894),
                        title: 'Hotline Dinas Kesehatan',
                        subtitle: 'WhatsApp Resmi Pendampingan Krisis Dinkes',
                        onTap: _openDinkesHotline,
                      ),

                      const Spacer(flex: 2),

                      // "Saya merasa lebih baik sekarang" Bottom Button
                      GestureDetector(
                        onTap: _handleDismiss,
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.65),
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
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconBg,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
