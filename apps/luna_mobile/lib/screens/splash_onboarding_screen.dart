import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../widgets/glass_card.dart';

class SplashOnboardingScreen extends StatefulWidget {
  const SplashOnboardingScreen({super.key});

  @override
  State<SplashOnboardingScreen> createState() => _SplashOnboardingScreenState();
}

class _SplashOnboardingScreenState extends State<SplashOnboardingScreen> {
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final token = await AppConfig.getToken();
    final refreshToken = await AppConfig.getRefreshToken();

    if (token == null && refreshToken == null) {
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
      return;
    }

    bool isAuthenticated = false;

    // 1. Try verifying access token with /auth/me
    try {
      if (token != null && token.isNotEmpty) {
        final headers = await AppConfig.getAuthHeaders();
        final res = await http
            .get(
              Uri.parse('${AppConfig.baseUrl}/auth/me'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final data = jsonDecode(res.body) as Map<String, dynamic>;
          final name = data['name']?.toString();
          final email = data['email']?.toString();
          if (name != null || email != null) {
            await AppConfig.setUserInfo(
              name: name ?? 'Sahabat LUNA',
              email: email ?? '',
            );
          }
          isAuthenticated = true;
        }
      }
    } catch (_) {}

    // 2. If access token is invalid/expired, attempt refresh token
    if (!isAuthenticated && refreshToken != null && refreshToken.isNotEmpty) {
      isAuthenticated = await AppConfig.refreshAccessToken();
    }

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      // Clear invalid local credentials
      if (token != null || refreshToken != null) {
        await AppConfig.clearToken();
      }
      if (mounted) {
        setState(() => _isCheckingAuth = false);
      }
    }
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
              Color(0xFFF3F5FF),
              Color(0xFFE9ECFF),
              Color(0xFFF8F9FE),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),

                          // Top Logo & Brand
                          Image.asset(
                            'assets/images/luna_logo.png',
                            width: 44,
                            height: 44,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.nightlight_round,
                                size: 40,
                                color: AppColors.primary,
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'LUNA',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            'PENDAMPING KESEHATAN MENTAL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary.withValues(alpha: 0.7),
                              letterSpacing: 1.5,
                            ),
                          ),

                          const Spacer(),

                          // Center 3D Glowing Orb Visual
                          Center(
                            child: Container(
                              width: 220,
                              height: 220,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const SweepGradient(
                                  colors: [
                                    Color(0xFFFFB6C1),
                                    Color(0xFFE2DAFF),
                                    Color(0xFFA7E6FF),
                                    Color(0xFF8B93FF),
                                    Color(0xFFFFB6C1),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    blurRadius: 40,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Container(
                                margin: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white,
                                      Color(0xFFEADBFF),
                                      Color(0xFFA7E6FF),
                                    ],
                                    center: Alignment(-0.3, -0.3),
                                    radius: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Bottom Content: Checking Auth or Onboarding Card
                          if (_isCheckingAuth)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 40.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Memuat ruang tenangmu...',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            // Bottom Glass Card Onboarding Content
                            GlassCard(
                              padding: const EdgeInsets.all(28.0),
                              child: Column(
                                children: [
                                  Text(
                                    'Selamat Datang di LUNA',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Ruang aman tempat pikiranmu didengar, dipahami, dan dirawat tanpa penilaian.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.textSecondary,
                                      height: 1.5,
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Primary Button: Start Your Journey
                                  CustomPillButton(
                                    text: 'Mulai Perjalananmu',
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/register');
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Login Link
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sudah punya akun? ',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(context, '/login');
                                        },
                                        child: Text(
                                          'Masuk',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

