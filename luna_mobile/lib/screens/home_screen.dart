import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});



  @override

  State<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;



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

                    // App Logo
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

                    // Notification Bell
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

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // Greeting

                      Text(

                        'Good evening, Alex.',

                        style: GoogleFonts.inter(

                          fontSize: 24,

                          fontWeight: FontWeight.w800,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 4),

                      Text(

                        "I'm here for you. How was your day?",

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          color: AppColors.textSecondary,

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Current Mood Card

                      GlassCard(

                        padding: const EdgeInsets.all(16),

                        child: Row(

                          children: [

                            Container(

                              width: 48,

                              height: 48,

                              decoration: const BoxDecoration(

                                shape: BoxShape.circle,

                                color: Color(0xFFF3EDFF),

                              ),

                              child: const Center(

                                child: Text('😌', style: TextStyle(fontSize: 24)),

                              ),

                            ),

                            const SizedBox(width: 14),

                            Column(

                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [

                                Text(

                                  'CURRENT MOOD',

                                  style: GoogleFonts.inter(

                                    fontSize: 11,

                                    fontWeight: FontWeight.w700,

                                    color: AppColors.textLight,

                                    letterSpacing: 0.5,

                                  ),

                                ),

                                const SizedBox(height: 2),

                                Text(

                                  'Peaceful',

                                  style: GoogleFonts.inter(

                                    fontSize: 15,

                                    fontWeight: FontWeight.w600,

                                    color: AppColors.textPrimary,

                                  ),

                                ),

                              ],

                            ),

                            const Spacer(),

                            IconButton(

                              icon: const Icon(Icons.edit_outlined, size: 20),

                              color: AppColors.primary,

                              onPressed: () {},

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 16),



                      // Quick Action Cards

                      _buildQuickCard(

                        icon: Icons.chat_bubble_outline,

                        iconBg: const Color(0xFF5358CB),

                        iconColor: Colors.white,

                        title: 'Talk with LUNA',

                        subtitle: 'Start a conversation',

                        onTap: () {

                          Navigator.pushNamed(context, '/chat');

                        },

                      ),

                      const SizedBox(height: 12),

                      _buildQuickCard(
                        icon: Icons.menu_book_outlined,
                        iconBg: const Color(0xFFE2DAFF),
                        iconColor: const Color(0xFF5358CB),
                        title: 'Write Diary',
                        subtitle: 'Reflect on your day',
                        onTap: () {
                          Navigator.pushNamed(context, '/diary');
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildQuickCard(
                        icon: Icons.psychology_outlined,
                        iconBg: const Color(0xFFE0F4FB),
                        iconColor: const Color(0xFF20667B),
                        title: 'Mental State',
                        subtitle: 'Quick check-in',
                        onTap: () {
                          Navigator.pushNamed(context, '/monitoring');
                        },
                      ),

                      const SizedBox(height: 24),



                      // Daily Progress

                      Row(

                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [

                          Text(

                            'Daily Progress',

                            style: GoogleFonts.inter(

                              fontSize: 16,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          const Icon(Icons.more_horiz, color: AppColors.textLight),

                        ],

                      ),

                      const SizedBox(height: 12),

                      GlassCard(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                        child: Column(

                          children: [

                            Stack(

                              alignment: Alignment.center,

                              children: [

                                const SizedBox(

                                  width: 90,

                                  height: 90,

                                  child: CircularProgressIndicator(

                                    value: 0.75,

                                    strokeWidth: 8,

                                    backgroundColor: Color(0xFFE0E6F8),

                                    valueColor: AlwaysStoppedAnimation<Color>(

                                      Color(0xFF489BB8),

                                    ),

                                  ),

                                ),

                                Column(

                                  mainAxisSize: MainAxisSize.min,

                                  children: [

                                    Text(

                                      '3/4',

                                      style: GoogleFonts.inter(

                                        fontSize: 18,

                                        fontWeight: FontWeight.w700,

                                        color: AppColors.textPrimary,

                                      ),

                                    ),

                                    Text(

                                      'GOALS',

                                      style: GoogleFonts.inter(

                                        fontSize: 9,

                                        fontWeight: FontWeight.w700,

                                        color: AppColors.textLight,

                                      ),

                                    ),

                                  ],

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            Text(

                              "You're doing great today.",

                              style: GoogleFonts.inter(

                                fontSize: 13,

                                color: AppColors.textSecondary,

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 24),



                      // Latest for You

                      Text(

                        'Latest for You',

                        style: GoogleFonts.inter(

                          fontSize: 16,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textPrimary,

                        ),

                      ),

                      const SizedBox(height: 12),

                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, '/recommendation');
                        },
                        child: Container(
                          height: 130,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFB8C2FC), Color(0xFFE8C6FB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Background Overlay & Pattern
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.black.withValues(alpha: 0.3),
                                        Colors.transparent,
                                      ],
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                    ),
                                  ),
                                ),
                              ),
                              // Content
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.8),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'MEDITATION',
                                        style: GoogleFonts.inter(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Morning Reflection',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Play Icon Overlay
                              Positioned(
                                right: 16,
                                top: 16,
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                    _buildNavItem(0, Icons.home, 'Home'),
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



  Widget _buildQuickCard({

    required IconData icon,

    required Color iconBg,

    required Color iconColor,

    required String title,

    required String subtitle,

    required VoidCallback onTap,

  }) {

    return GlassCard(
      width: double.infinity,
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      child: Row(

        children: [

          Container(

            width: 44,

            height: 44,

            decoration: BoxDecoration(

              color: iconBg,

              borderRadius: BorderRadius.circular(14),

            ),

            child: Icon(icon, color: iconColor, size: 22),

          ),

          const SizedBox(width: 14),

          Column(

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

              const SizedBox(height: 2),

              Text(

                subtitle,

                style: GoogleFonts.inter(

                  fontSize: 12,

                  color: AppColors.textLight,

                ),

              ),

            ],

          ),

        ],

      ),

    );

  }



  Widget _buildNavItem(int index, IconData icon, String label, {String? route}) {

    final isSelected = _currentIndex == index;

    return GestureDetector(

      onTap: () {

        setState(() {

          _currentIndex = index;

        });

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

