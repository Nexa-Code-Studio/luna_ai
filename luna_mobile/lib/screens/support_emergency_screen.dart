import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';



class SupportEmergencyScreen extends StatelessWidget {

  const SupportEmergencyScreen({super.key});



  @override

  Widget build(BuildContext context) {

    return Scaffold(

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

          child: Padding(

            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),

            child: Column(

              children: [

                const Spacer(flex: 1),



                // Heart Badge Visual

                Container(

                  width: 90,

                  height: 90,

                  decoration: BoxDecoration(

                    shape: BoxShape.circle,

                    color: const Color(0xFFFFE0E3),

                    boxShadow: [

                      BoxShadow(

                        color: const Color(0xFFE57373).withValues(alpha: 0.2),

                        blurRadius: 30,

                        offset: const Offset(0, 10),

                      ),

                    ],

                  ),

                  child: const Icon(

                    Icons.favorite,

                    color: Color(0xFFE57373),

                    size: 40,

                  ),

                ),

                const SizedBox(height: 28),



                // Title & Subtitle

                Text(

                  'Take a deep breath.',

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

                    "LUNA noticed that you may need additional support right now. You don't have to navigate this alone.",

                    textAlign: TextAlign.center,

                    style: GoogleFonts.inter(

                      fontSize: 14,

                      color: AppColors.textSecondary,

                      height: 1.5,

                    ),

                  ),

                ),

                const SizedBox(height: 36),



                // Action Pill Card 1: Call a Trusted Person

                _buildSupportPillCard(

                  icon: Icons.perm_contact_calendar_outlined,

                  iconBg: const Color(0xFFFFDCDD),

                  iconColor: const Color(0xFFE57373),

                  title: 'Call a Trusted Person',

                  onTap: () {},

                ),

                const SizedBox(height: 14),



                // Action Pill Card 2: Chat with a Professional

                _buildSupportPillCard(

                  icon: Icons.chat_bubble_outline,

                  iconBg: const Color(0xFFE4DCFF),

                  iconColor: const Color(0xFF6C5CE7),

                  title: 'Chat with a Professional',

                  onTap: () {},

                ),

                const SizedBox(height: 14),



                // Action Pill Card 3: Crisis Hotlines

                _buildSupportPillCard(

                  icon: Icons.language,

                  iconBg: const Color(0xFFD7F3FF),

                  iconColor: const Color(0xFF00CEC9),

                  title: 'Crisis Hotlines',

                  onTap: () {},

                ),

                const Spacer(flex: 2),



                // "I'm feeling better now" Bottom Button

                GestureDetector(

                  onTap: () {

                    Navigator.pop(context);

                  },

                  child: Container(

                    width: double.infinity,

                    height: 54,

                    decoration: BoxDecoration(

                      color: Colors.white.withValues(alpha: 0.6),

                      borderRadius: BorderRadius.circular(999),

                      border: Border.all(

                        color: const Color(0xFFE57373).withValues(alpha: 0.4),

                        width: 1.2,

                      ),

                    ),

                    child: Center(

                      child: Text(

                        "I'm feeling better now",

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

    );

  }



  Widget _buildSupportPillCard({

    required IconData icon,

    required Color iconBg,

    required Color iconColor,

    required String title,

    required VoidCallback onTap,

  }) {

    return GestureDetector(

      onTap: onTap,

      child: Container(

        width: double.infinity,

        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

        decoration: BoxDecoration(

          color: Colors.white.withValues(alpha: 0.9),

          borderRadius: BorderRadius.circular(999),

          border: Border.all(color: Colors.white, width: 1.5),

          boxShadow: [

            BoxShadow(

              color: Colors.black.withValues(alpha: 0.03),

              blurRadius: 16,

              offset: const Offset(0, 4),

            ),

          ],

        ),

        child: Row(

          children: [

            Container(

              width: 44,

              height: 44,

              decoration: BoxDecoration(

                shape: BoxShape.circle,

                color: iconBg,

              ),

              child: Icon(icon, color: iconColor, size: 22),

            ),

            const SizedBox(width: 16),

            Expanded(

              child: Text(

                title,

                style: GoogleFonts.inter(

                  fontSize: 15,

                  fontWeight: FontWeight.w600,

                  color: AppColors.textPrimary,

                ),

              ),

            ),

            const Icon(

              Icons.arrow_forward_ios,

              size: 16,

              color: AppColors.textLight,

            ),

            const SizedBox(width: 8),

          ],

        ),

      ),

    );

  }

}

