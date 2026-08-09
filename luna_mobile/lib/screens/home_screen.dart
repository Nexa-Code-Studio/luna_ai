import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/floating_nav_bar.dart';

import '../widgets/glass_card.dart';



class HomeScreen extends StatefulWidget {

  const HomeScreen({super.key});



  @override

  State<HomeScreen> createState() => _HomeScreenState();

}



class _HomeScreenState extends State<HomeScreen> {

  int _currentIndex = 0;



  void _onTabTapped(int index) {

    setState(() {

      _currentIndex = index;

    });

    switch (index) {

      case 0:

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



                  // Scrollable Body Content

                  Expanded(

                    child: SingleChildScrollView(

                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          // User Greeting Header

                          Text(

                            'Halo, Sarah! 👋',

                            style: GoogleFonts.inter(

                              fontSize: 24,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            'Bagaimana perasaanmu hari ini?',

                            style: GoogleFonts.inter(

                              fontSize: 14,

                              color: AppColors.textSecondary,

                            ),

                          ),

                          const SizedBox(height: 16),



                          // Current Mood Card

                          GlassCard(

                            width: double.infinity,

                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),

                            child: Row(

                              children: [

                                Container(

                                  width: 48,

                                  height: 48,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFFEADBFF),

                                    borderRadius: BorderRadius.circular(16),

                                  ),

                                  child: const Center(

                                    child: Text(

                                      '😌',

                                      style: TextStyle(fontSize: 26),

                                    ),

                                  ),

                                ),

                                const SizedBox(width: 16),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Text(

                                        'Suasana Hati Terdeteksi',

                                        style: GoogleFonts.inter(

                                          fontSize: 12,

                                          color: AppColors.textLight,

                                          fontWeight: FontWeight.w500,

                                        ),

                                      ),

                                      const SizedBox(height: 2),

                                      Text(

                                        'Tenang & Damai',

                                        style: GoogleFonts.inter(

                                          fontSize: 16,

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.textPrimary,

                                        ),

                                      ),

                                    ],

                                  ),

                                ),

                                const Icon(

                                  Icons.chevron_right,

                                  color: AppColors.textLight,

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(height: 20),



                          // Quick Action Cards

                          _buildQuickCard(

                            icon: Icons.chat_bubble_outline,

                            iconBg: const Color(0xFF5358CB),

                            iconColor: Colors.white,

                            title: 'Curhat ke LUNA',

                            subtitle: 'Mulai percakapan hangat',

                            onTap: () {

                              Navigator.pushNamed(context, '/chat');

                            },

                          ),

                          const SizedBox(height: 12),

                          _buildQuickCard(

                            icon: Icons.menu_book_outlined,

                            iconBg: const Color(0xFFE2DAFF),

                            iconColor: const Color(0xFF5358CB),

                            title: 'Tulis Jurnal AI',

                            subtitle: 'Refleksikan harimu',

                            onTap: () {

                              Navigator.pushNamed(context, '/diary');

                            },

                          ),

                          const SizedBox(height: 12),

                          _buildQuickCard(

                            icon: Icons.psychology_outlined,

                            iconBg: const Color(0xFFE0F4FB),

                            iconColor: const Color(0xFF20667B),

                            title: 'Ritem Emosional',

                            subtitle: 'Cek grafik kesehatan mental',

                            onTap: () {

                              Navigator.pushNamed(context, '/monitoring');

                            },

                          ),

                          const SizedBox(height: 24),



                          // Daily Progress Section

                          Row(

                            mainAxisAlignment: MainAxisAlignment.spaceBetween,

                            children: [

                              Text(

                                'Progres Harian',

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

                                          'TARGET',

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

                                  'Kamu luar biasa hari ini.',

                                  style: GoogleFonts.inter(

                                    fontSize: 13,

                                    color: AppColors.textSecondary,

                                  ),

                                ),

                              ],

                            ),

                          ),

                          const SizedBox(height: 24),



                          // Latest for You Section

                          Text(

                            'Rekomendasi Terkini',

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

                                            'MEDITASI',

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

                                          'Refleksi Pagi & Ketenangan',

                                          style: GoogleFonts.inter(

                                            fontSize: 16,

                                            fontWeight: FontWeight.w700,

                                            color: Colors.white,

                                          ),

                                        ),

                                      ],

                                    ),

                                  ),

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

}

