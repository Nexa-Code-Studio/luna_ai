import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class RecommendationScreen extends StatefulWidget {

  const RecommendationScreen({super.key});



  @override

  State<RecommendationScreen> createState() => _RecommendationScreenState();

}



class _RecommendationScreenState extends State<RecommendationScreen> {

  final int _currentIndex = 0; // Home/Recommendations active



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

                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Title & Subtitle

                      Text(

                        'For Your Wellbeing',

                        style: GoogleFonts.inter(

                          fontSize: 24,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 6),

                      Text(

                        'Here are a few suggestions to help you ground yourself today.',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          color: AppColors.textSecondary,

                          height: 1.4,

                        ),

                      ),

                      const SizedBox(height: 24),



                      // Recommendation Card 1: Breathing Exercise

                      _buildRecCard(

                        icon: Icons.air,

                        iconBg: const Color(0xFF8B93FF),

                        title: 'Breathing Exercise',

                        subtitle: 'Take a moment to center yourself. (3 mins)',

                        onTap: () {},

                      ),

                      const SizedBox(height: 14),



                      // Recommendation Card 2: Daily Reflection Question

                      _buildRecCard(

                        icon: Icons.edit_note,

                        iconBg: const Color(0xFFC3B8FF),

                        title: 'Daily Reflection Question',

                        subtitle: 'What is one thing that brought you comfort today?',

                        onTap: () {},

                      ),

                      const SizedBox(height: 14),



                      // Recommendation Card 3: Self-Care

                      _buildRecCard(

                        icon: Icons.directions_walk,

                        iconBg: const Color(0xFF489BB8),

                        title: 'Self-Care',

                        subtitle: 'Take a 10 min walk.',

                        onTap: () {},

                      ),

                      const SizedBox(height: 14),



                      // Recommendation Card 4: Therapy Exercise

                      _buildRecCard(

                        icon: Icons.psychology,

                        iconBg: const Color(0xFF9EA3C0),

                        title: 'Therapy Exercise',

                        subtitle: 'Cognitive Reframing.',

                        onTap: () {},

                      ),

                      const SizedBox(height: 24),

                    ],

                  ),

                ),

              ),



              // Bottom Navigation Bar

              Container(

                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                decoration: BoxDecoration(

                  color: Colors.white.withValues(alpha: 0.9),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.04),

                      blurRadius: 20,

                      offset: const Offset(0, -4),

                    ),

                  ],

                ),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [

                    _buildNavItem(0, Icons.home, 'Home', route: '/home'),

                    _buildNavItem(1, Icons.chat_bubble_outline, 'Chat', route: '/chat'),

                    _buildNavItem(2, Icons.menu_book_outlined, 'Diary', route: '/diary'),

                    _buildNavItem(3, Icons.show_chart, 'Trends', route: '/monitoring'),

                  ],

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



  Widget _buildNavItem(int index, IconData icon, String label, {String? route}) {

    final isSelected = _currentIndex == index;

    return GestureDetector(

      onTap: () {

        if (route != null) {

          Navigator.pushNamed(context, route);

        }

      },

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        decoration: BoxDecoration(

          color: isSelected ? AppColors.primaryContainer : Colors.transparent,

          borderRadius: BorderRadius.circular(999),

        ),

        child: Row(

          children: [

            Icon(

              icon,

              size: 20,

              color: isSelected ? AppColors.primary : AppColors.textLight,

            ),

            if (isSelected) ...[

              const SizedBox(width: 6),

              Text(

                label,

                style: GoogleFonts.inter(

                  fontSize: 12,

                  fontWeight: FontWeight.w700,

                  color: AppColors.primary,

                ),

              ),

            ],

          ],

        ),

      ),

    );

  }

}

