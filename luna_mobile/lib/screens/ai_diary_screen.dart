import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/floating_nav_bar.dart';

import '../widgets/glass_card.dart';



class AiDiaryScreen extends StatefulWidget {

  const AiDiaryScreen({super.key});



  @override

  State<AiDiaryScreen> createState() => _AiDiaryScreenState();

}



class _AiDiaryScreenState extends State<AiDiaryScreen> {

  int _currentIndex = 1; // Jurnal tab selected



  void _onTabTapped(int index) {

    setState(() {

      _currentIndex = index;

    });

    switch (index) {

      case 0:

        Navigator.pushNamed(context, '/home');

        break;

      case 1:

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

                        children: [

                          // Title & Date Header

                          Text(

                            'Jurnal Hari Ini',

                            style: GoogleFonts.inter(

                              fontSize: 24,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          const SizedBox(height: 4),

                          Text(

                            '24 Oktober 2023',

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

                                  'Tenang & Reflektif',

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

                                      'WAWASAN AI',

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

                                  'Hari ini kamu merasa cemas tentang tanggung jawab akademik, tetapi menunjukkan motivasi yang kuat untuk menyelesaikan masalah.',

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

                                      'PERISTIWA PENTING',

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

                                _buildBulletItem('Sesi belajar pagi untuk persiapan ujian tengah semester'),

                                const SizedBox(height: 8),

                                _buildBulletItem('Minum kopi & mengobrol hangat dengan Sarah'),

                                const SizedBox(height: 8),

                                _buildBulletItem('Menyelesaikan review materi Bab 4'),

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

                                      'REFLEKSI EMOSIONAL',

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

                                  'Meskipun memulai hari dengan rasa gugup menghadapi ujian, membagi tugas menjadi bagian-bagian kecil sangat membantu. Saya menemukan ketenangan saat jalan santai di sore hari, menyadari bahwa proses lebih berharga daripada kesempurnaan.',

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

}

