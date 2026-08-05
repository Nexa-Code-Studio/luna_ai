import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';

class SplashOnboardingScreen extends StatelessWidget {

  const SplashOnboardingScreen({super.key});

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

                            'MENTAL HEALTH',

                            style: GoogleFonts.inter(

                              fontSize: 10,

                              fontWeight: FontWeight.w700,

                              color: AppColors.primary.withValues(alpha: 0.7),

                              letterSpacing: 1.5,

                            ),

                          ),

                          const Spacer(),

                          const SizedBox(height: 12),

                          // Center 3D Iridescent Sphere Graphic

                          Container(

                            width: 180,

                            height: 180,

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

                                  color: AppColors.primary.withValues(alpha: 0.25),

                                  blurRadius: 30,

                                  spreadRadius: 4,

                                  offset: const Offset(0, 8),

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

                                    Color(0xFFE0DAFF),

                                    Color(0xFF7A83FF),

                                  ],

                                  center: Alignment(-0.3, -0.3),

                                  radius: 0.8,

                                ),

                              ),

                            ),

                          ),

                          const SizedBox(height: 12),

                          const Spacer(),

                          // Bottom Glass Card

                          GlassCard(

                            padding: const EdgeInsets.all(20),

                            child: Column(

                              children: [

                                Text(

                                  'Welcome to Luna',

                                  textAlign: TextAlign.center,

                                  style: GoogleFonts.inter(

                                    fontSize: 22,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textPrimary,

                                  ),

                                ),

                                const SizedBox(height: 10),

                                Text(

                                  "Your personal mental health companion. Take a deep breath, we're here for you.",

                                  textAlign: TextAlign.center,

                                  style: GoogleFonts.inter(

                                    fontSize: 13,

                                    fontWeight: FontWeight.w400,

                                    color: AppColors.textSecondary,

                                    height: 1.4,

                                  ),

                                ),

                                const SizedBox(height: 20),

                                CustomPillButton(

                                  text: 'Start Your Journey',

                                  suffixIcon: Icons.arrow_forward,

                                  onPressed: () {

                                    Navigator.pushNamed(context, '/register');

                                  },

                                ),

                                const SizedBox(height: 14),

                                GestureDetector(

                                  onTap: () {

                                    Navigator.pushNamed(context, '/login');

                                  },

                                  child: RichText(

                                    text: TextSpan(

                                      text: 'Already have an account? ',

                                      style: GoogleFonts.inter(

                                        fontSize: 13,

                                        color: AppColors.textLight,

                                      ),

                                      children: [

                                        TextSpan(

                                          text: 'Log in',

                                          style: GoogleFonts.inter(

                                            fontSize: 13,

                                            fontWeight: FontWeight.w600,

                                            color: AppColors.primary,

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(height: 16),

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

