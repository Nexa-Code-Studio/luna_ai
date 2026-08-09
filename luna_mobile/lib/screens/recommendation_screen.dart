import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/floating_nav_bar.dart';

import '../widgets/glass_card.dart';



class RecommendationScreen extends StatefulWidget {

  const RecommendationScreen({super.key});



  @override

  State<RecommendationScreen> createState() => _RecommendationScreenState();

}



class _RecommendationScreenState extends State<RecommendationScreen> {

  int _currentIndex = 0; // Beranda/Rekomendasi aktif



  void _onTabTapped(int index) {

    setState(() {

      _currentIndex = index;

    });

    switch (index) {

      case 0:

        Navigator.pushNamed(context, '/home');

        break;

      case 1:

        Navigator.pushNamed(context, '/diary');

        break;

      case 2:

        Navigator.pushNamed(context, '/monitoring');

        break;

      case 3:

        Navigator.pushNamed(context, '/profile');

        break;

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

              Color(0xFFF6F8FF),

              Color(0xFFEFF2FE),

              Color(0xFFF8F9FE),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: SafeArea(

          child: Stack(

            children: [

              Column(

                children: [

                  // Header Bar

                  Padding(

                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),

                    child: Row(

                      children: [

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

                          'LUNA',

                          style: GoogleFonts.inter(

                            fontSize: 16,

                            fontWeight: FontWeight.w700,

                            color: AppColors.primary,

                          ),

                        ),

                        const Spacer(),

                        IconButton(

                          icon: const Icon(Icons.notifications_none_outlined),

                          color: AppColors.primary,

                          onPressed: () {},

                        ),

                      ],

                    ),

                  ),



                  // Scrollable Content

                  Expanded(

                    child: SingleChildScrollView(

                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          // Title & Subtitle

                          Text(

                            'Panduan Ketenanganmu',

                            style: GoogleFonts.inter(

                              fontSize: 24,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          const SizedBox(height: 6),

                          Text(

                            'Berikut beberapa saran sederhana untuk membantumu merasa lebih tenang hari ini.',

                            style: GoogleFonts.inter(

                              fontSize: 14,

                              color: AppColors.textSecondary,

                              height: 1.4,

                            ),

                          ),

                          const SizedBox(height: 24),



                          // Recommendation Card 1: Latihan Pernapasan

                          _buildRecCard(

                            icon: Icons.air,

                            iconBg: const Color(0xFF8B93FF),

                            title: 'Latihan Pernapasan',

                            subtitle: 'Luangkan waktu sejenak untuk menenangkan diri. (3 menit)',

                            onTap: () {},

                          ),

                          const SizedBox(height: 14),



                          // Recommendation Card 2: Pertanyaan Refleksi Harian

                          _buildRecCard(

                            icon: Icons.edit_note,

                            iconBg: const Color(0xFFC3B8FF),

                            title: 'Pertanyaan Refleksi Harian',

                            subtitle: 'Apa satu hal yang memberimu rasa nyaman hari ini?',

                            onTap: () {},

                          ),

                          const SizedBox(height: 14),



                          // Recommendation Card 3: Perawatan Diri

                          _buildRecCard(

                            icon: Icons.directions_walk,

                            iconBg: const Color(0xFF489BB8),

                            title: 'Perawatan Diri',

                            subtitle: 'Jalan santai selama 10 menit.',

                            onTap: () {},

                          ),

                          const SizedBox(height: 14),



                          // Recommendation Card 4: Latihan Reframing Kognitif

                          _buildRecCard(

                            icon: Icons.psychology,

                            iconBg: const Color(0xFF9EA3C0),

                            title: 'Latihan Reframing Kognitif',

                            subtitle: 'Melihat masalah dari sudut pandang yang lebih positif.',

                            onTap: () {},

                          ),

                          const SizedBox(height: 24),

                        ],

                      ),

                    ),

                  ),

                ],

              ),



              // Floating Bottom Navigation Bar Widget

              Positioned(

                left: 0,

                right: 0,

                bottom: 0,

                child: FloatingNavBar(

                  currentIndex: _currentIndex,

                  onTap: _onTabTapped,

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildRecCard({

    required IconData icon,

    required Color iconBg,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

  }) {

    return GlassCard(

      width: double.infinity,

      onTap: onTap,

      padding: const EdgeInsets.all(18),

      child: Row(

        children: [

          Container(

            width: 46,

            height: 46,

            decoration: BoxDecoration(

              color: iconBg,

              shape: BoxShape.circle,

            ),

            child: Icon(icon, color: Colors.white, size: 22),

          ),

          const SizedBox(width: 14),

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

                const SizedBox(height: 4),

                Text(

                  subtitle,

                  style: GoogleFonts.inter(

                    fontSize: 13,

                    color: AppColors.textSecondary,

                    height: 1.3,

                  ),

                ),

              ],

            ),

          ),

          const SizedBox(width: 8),

          const Icon(

            Icons.arrow_forward_ios,

            size: 16,

            color: AppColors.textLight,

          ),

        ],

      ),

    );

  }

}

