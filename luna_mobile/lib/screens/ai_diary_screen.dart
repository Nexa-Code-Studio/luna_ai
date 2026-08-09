import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class AiDiaryScreen extends StatefulWidget {

  const AiDiaryScreen({super.key});



  @override

  State<AiDiaryScreen> createState() => _AiDiaryScreenState();

}



class _AiDiaryScreenState extends State<AiDiaryScreen> {

  final int _currentIndex = 2; // Diary tab selected



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



              // Scrollable Body Content

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),

                  child: Column(

                    children: [

                      // Title & Date Header

                      Text(

                        "Today's Diary",

                        style: GoogleFonts.inter(

                          fontSize: 24,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        'October 24, 2023',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          color: AppColors.textSecondary,

                        ),

                      ),

                      const SizedBox(height: 12),

                      // Mood Tag Pill

                      Container(

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

                        decoration: BoxDecoration(

                          color: const Color(0xFFEADBFF),

                          borderRadius: BorderRadius.circular(999),

                        ),

                        child: Row(

                          mainAxisSize: MainAxisSize.min,

                          children: [

                            const Icon(

                              Icons.spa_outlined,

                              size: 16,

                              color: AppColors.primary,

                            ),

                            const SizedBox(width: 6),

                            Text(

                              'Calm & Reflective',

                              style: GoogleFonts.inter(

                                fontSize: 13,

                                fontWeight: FontWeight.w600,

                                color: AppColors.primary,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Card 1: AI INSIGHT

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: AppColors.primary,

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.auto_awesome,

                                    color: Colors.white,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Text(

                                  'AI INSIGHT',

                                  style: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.primary,

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            Text(

                              'Today you felt anxious about academic responsibilities but showed strong motivation to solve problems.',

                              style: GoogleFonts.inter(

                                fontSize: 14,

                                color: AppColors.textPrimary,

                                height: 1.5,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Card 2: IMPORTANT EVENTS

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFF489BB8),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.calendar_today_outlined,

                                    color: Colors.white,

                                    size: 18,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Text(

                                  'IMPORTANT EVENTS',

                                  style: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: FontWeight.w700,

                                    color: const Color(0xFF20667B),

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            _buildBulletItem('Morning study session for midterms'),

                            const SizedBox(height: 8),

                            _buildBulletItem('Coffee catch-up with Sarah'),

                            const SizedBox(height: 8),

                            _buildBulletItem('Completed chapter 4 review'),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Card 3: EMOTIONAL REFLECTION

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFF605A79),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.psychology_outlined,

                                    color: Colors.white,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 10),

                                Text(

                                  'EMOTIONAL REFLECTION',

                                  style: GoogleFonts.inter(

                                    fontSize: 12,

                                    fontWeight: FontWeight.w700,

                                    color: const Color(0xFF605A79),

                                    letterSpacing: 0.8,

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            Text(

                              'Despite starting the day with a knot in my stomach regarding the upcoming exams, breaking down the tasks helped immensely. I found a sense of peace during the afternoon walk, realizing that progress is better than perfection.',

                              style: GoogleFonts.inter(

                                fontSize: 14,

                                color: AppColors.textPrimary,

                                height: 1.5,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 24),

                    ],

                  ),

                ),

              ),



              // Bottom Navigation Bar with 5 Tabs and Persistent Labels

              Container(

                padding: const EdgeInsets.fromLTRB(8, 12, 8, 14),

                decoration: BoxDecoration(

                  color: Colors.white.withValues(alpha: 0.95),

                  boxShadow: [

                    BoxShadow(

                      color: Colors.black.withValues(alpha: 0.05),

                      blurRadius: 20,

                      offset: const Offset(0, -4),

                    ),

                  ],

                ),

                child: Row(

                  mainAxisAlignment: MainAxisAlignment.spaceAround,

                  children: [

                    _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', route: '/home'),

                    _buildNavItem(1, Icons.chat_bubble_outline, Icons.chat_bubble, 'Chat', route: '/chat'),

                    _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book, 'Diary'),

                    _buildNavItem(3, Icons.show_chart_outlined, Icons.show_chart, 'Trends', route: '/monitoring'),

                    _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile', route: '/profile'),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }



  Widget _buildBulletItem(String text) {

    return Row(

      crossAxisAlignment: CrossAxisAlignment.start,

      children: [

        Container(

          margin: const EdgeInsets.only(top: 6),

          width: 6,

          height: 6,

          decoration: const BoxDecoration(

            shape: BoxShape.circle,

            color: AppColors.primary,

          ),

        ),

        const SizedBox(width: 10),

        Expanded(

          child: Text(

            text,

            style: GoogleFonts.inter(

              fontSize: 14,

              color: AppColors.textPrimary,

            ),

          ),

        ),

      ],

    );

  }



  Widget _buildNavItem(

    int index,

    IconData iconUnselected,

    IconData iconSelected,

    String label, {

    String? route,

  }) {

    final isSelected = _currentIndex == index;

    return GestureDetector(

      onTap: () {

        if (route != null) {

          Navigator.pushNamed(context, route);

        }

      },

      child: Container(

        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),

        decoration: BoxDecoration(

          color: isSelected ? AppColors.primaryContainer : Colors.transparent,

          borderRadius: BorderRadius.circular(16),

        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Icon(

              isSelected ? iconSelected : iconUnselected,

              size: 22,

              color: isSelected ? AppColors.primary : AppColors.textLight,

            ),

            const SizedBox(height: 4),

            Text(

              label,

              style: GoogleFonts.inter(

                fontSize: 11,

                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,

                color: isSelected ? AppColors.primary : AppColors.textLight,

              ),

            ),

          ],

        ),

      ),

    );

  }

}

