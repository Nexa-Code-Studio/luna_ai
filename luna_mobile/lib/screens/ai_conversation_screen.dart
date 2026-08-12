import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class AiConversationScreen extends StatelessWidget {

  const AiConversationScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [

              Color(0xFFF6F8FF),

              Color(0xFFEFF2FE),

              Color(0xFFF8F9FE),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: SafeArea(

          child: Column(

            children: [

              // Header Bar

              Padding(

                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),

                child: Row(

                  children: [

                    IconButton(

                      icon: const Icon(Icons.arrow_back),

                      color: AppColors.textPrimary,

                      onPressed: () {

                        Navigator.pop(context);

                      },

                    ),

                    Image.asset(

                      'assets/images/luna_logo.png',

                      width: 32,

                      height: 32,

                      fit: BoxFit.contain,

                      errorBuilder: (context, error, stackTrace) {

                        return const Icon(

                          Icons.nightlight_round,

                          size: 28,

                          color: AppColors.primary,

                        );

                      },

                    ),

                    const SizedBox(width: 8),

                    Text(

                      'Sesi Suara LUNA',

                      style: GoogleFonts.inter(

                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: AppColors.primary,

                      ),

                    ),

                    const Spacer(),

                    Container(

                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

                      decoration: BoxDecoration(

                        color: AppColors.primaryContainer,

                        borderRadius: BorderRadius.circular(999),

                      ),

                      child: Row(

                        children: [

                          Container(

                            width: 6,

                            height: 6,

                            decoration: const BoxDecoration(

                              shape: BoxShape.circle,

                              color: Color(0xFF4CAF50),

                            ),

                          ),

                          const SizedBox(width: 6),

                          Text(

                            'MODE SUARA AI',

                            style: GoogleFonts.inter(

                              fontSize: 10,

                              fontWeight: FontWeight.w700,

                              color: AppColors.primary,

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

              ),

              const Divider(height: 1, color: Color(0xFFEBECEF)),



              // Scrollable Content Body

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

                  child: Column(

                    children: [

                      const SizedBox(height: 12),



                      // 3D Glowing Iridescent Orb Visual

                      Center(

                        child: Container(

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

                                color: AppColors.primary.withValues(alpha: 0.3),

                                blurRadius: 40,

                                spreadRadius: 4,

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

                            child: const Center(

                              child: Icon(

                                Icons.graphic_eq,

                                size: 48,

                                color: AppColors.primary,

                              ),

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(height: 28),



                      // Title & Subtitle Greeting

                      Text(

                        'LUNA Siap Mendengarkan',

                        textAlign: TextAlign.center,

                        style: GoogleFonts.inter(

                          fontSize: 22,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 8),

                      Padding(

                        padding: const EdgeInsets.symmetric(horizontal: 16.0),

                        child: Text(

                          'Bicara secara alami kapan saja tanpa mengetik. LUNA hadir mendampingi dan mendengarkan perasaanmu.',

                          textAlign: TextAlign.center,

                          style: GoogleFonts.inter(

                            fontSize: 14,

                            color: AppColors.textSecondary,

                            height: 1.5,

                          ),

                        ),

                      ),

                      const SizedBox(height: 32),



                      // Main Action Button: Mulai Sesi Suara

                      CustomPillButton(

                        text: 'Mulai Sesi Suara',

                        suffixIcon: Icons.mic,

                        onPressed: () {

                          Navigator.pushNamed(context, '/voice_call');

                        },

                      ),

                      const SizedBox(height: 36),



                      // Recent Voice Sessions Section

                      Align(

                        alignment: Alignment.centerLeft,

                        child: Text(

                          'RIWAYAT SESI SUARA TERAKHIR',

                          style: GoogleFonts.inter(

                            fontSize: 11,

                            fontWeight: FontWeight.w700,

                            color: AppColors.textLight,

                            letterSpacing: 0.8,

                          ),

                        ),

                      ),

                      const SizedBox(height: 12),



                      // History Card 1

                      _buildSessionHistoryCard(

                        title: 'Sesi Refleksi Pagi',

                        duration: '04:12',

                        date: 'Hari ini, 09:15',

                        moodTag: 'Tenang & Reflektif',

                        onTap: () {},

                      ),

                      const SizedBox(height: 10),



                      // History Card 2

                      _buildSessionHistoryCard(

                        title: 'Curhat Bebas Sore Hari',

                        duration: '06:45',

                        date: 'Kemarin, 16:30',

                        moodTag: 'Lega & Nyaman',

                        onTap: () {},

                      ),

                      const SizedBox(height: 24),

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



  Widget _buildSessionHistoryCard({

    required String title,

    required String duration,

    required String date,

    required String moodTag,

    required VoidCallback onTap,

  }) {

    return GlassCard(

      width: double.infinity,

      onTap: onTap,

      padding: const EdgeInsets.all(16),

      child: Row(

        children: [

          Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: AppColors.primaryContainer,

              borderRadius: BorderRadius.circular(14),

            ),

            child: const Icon(

              Icons.volume_up_outlined,

              color: AppColors.primary,

              size: 22,

            ),

          ),

          const SizedBox(width: 14),

          Expanded(

            child: Column(

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                Text(

                  title,

                  style: GoogleFonts.inter(

                    fontSize: 14,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textPrimary,

                  ),

                ),

                const SizedBox(height: 2),

                Text(

                  '$date • $duration',

                  style: GoogleFonts.inter(

                    fontSize: 12,

                    color: AppColors.textLight,

                  ),

                ),

              ],

            ),

          ),

          Container(

            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),

            decoration: BoxDecoration(

              color: const Color(0xFFEADBFF),

              borderRadius: BorderRadius.circular(999),

            ),

            child: Text(

              moodTag,

              style: GoogleFonts.inter(

                fontSize: 11,

                fontWeight: FontWeight.w600,

                color: AppColors.primary,

              ),

            ),

          ),

        ],

      ),

    );

  }

}

