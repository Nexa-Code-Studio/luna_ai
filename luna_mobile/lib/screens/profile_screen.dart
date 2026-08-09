import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/glass_card.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  final int _currentIndex = 4; // Profile tab index



  bool _memoryEnabled = true;

  bool _notificationsEnabled = true;



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

                      'Profile & Settings',

                      style: GoogleFonts.inter(

                        fontSize: 16,

                        fontWeight: FontWeight.w700,

                        color: AppColors.primary,

                      ),

                    ),

                    const Spacer(),

                    IconButton(

                      icon: const Icon(Icons.settings_outlined),

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

                      // User Header Glass Card

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Row(

                          children: [

                            CircleAvatar(

                              radius: 30,

                              backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),

                              child: const Icon(

                                Icons.person,

                                size: 36,

                                color: AppColors.primary,

                              ),

                            ),

                            const SizedBox(width: 16),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(

                                    'Sarah Jenkins',

                                    style: GoogleFonts.inter(

                                      fontSize: 18,

                                      fontWeight: FontWeight.w800,

                                      color: AppColors.textPrimary,

                                    ),

                                  ),

                                  const SizedBox(height: 2),

                                  Text(

                                    'sarah.j@example.com',

                                    style: GoogleFonts.inter(

                                      fontSize: 13,

                                      color: AppColors.textSecondary,

                                    ),

                                  ),

                                  const SizedBox(height: 8),

                                  Container(

                                    padding: const EdgeInsets.symmetric(

                                      horizontal: 10,

                                      vertical: 4,

                                    ),

                                    decoration: BoxDecoration(

                                      color: AppColors.primaryContainer,

                                      borderRadius: BorderRadius.circular(999),

                                    ),

                                    child: Text(

                                      'LUNA Companion Member',

                                      style: GoogleFonts.inter(

                                        fontSize: 11,

                                        fontWeight: FontWeight.w700,

                                        color: AppColors.primary,

                                      ),

                                    ),

                                  ),

                                ],

                              ),

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Section 1: AI & Long-Term Memory

                      Text(

                        'AI & Long-Term Memory',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                        child: Column(

                          children: [

                            SwitchListTile(

                              activeThumbColor: AppColors.primary,

                              title: Text(

                                'Enable Long-Term Memory',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: AppColors.textPrimary,

                                ),

                              ),

                              subtitle: Text(

                                'Allows LUNA to remember key emotional rhythms and goals',

                                style: GoogleFonts.inter(

                                  fontSize: 12,

                                  color: AppColors.textSecondary,

                                ),

                              ),

                              value: _memoryEnabled,

                              onChanged: (val) {

                                setState(() {

                                  _memoryEnabled = val;

                                });

                              },

                            ),

                            const Divider(height: 1, color: Color(0xFFEBECEF)),

                            ListTile(

                              leading: const Icon(Icons.delete_outline, color: Colors.redAccent),

                              title: Text(

                                'Clear AI Memory Logs',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: Colors.redAccent,

                                ),

                              ),

                              onTap: () {},

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Section 2: Crisis & Emergency Contacts

                      Text(

                        'Crisis & Safety Plan',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                        child: Column(

                          children: [

                            ListTile(

                              leading: const Icon(Icons.phone_outlined, color: AppColors.primary),

                              title: Text(

                                'Emergency Contact',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: AppColors.textPrimary,

                                ),

                              ),

                              subtitle: Text(

                                'Mom (+62 812-3456-7890)',

                                style: GoogleFonts.inter(

                                  fontSize: 12,

                                  color: AppColors.textSecondary,

                                ),

                              ),

                              trailing: const Icon(Icons.edit_outlined, size: 18),

                              onTap: () {},

                            ),

                            const Divider(height: 1, color: Color(0xFFEBECEF)),

                            ListTile(

                              leading: const Icon(Icons.favorite_outline, color: Color(0xFFE57373)),

                              title: Text(

                                'Open Crisis Support Center',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: AppColors.textPrimary,

                                ),

                              ),

                              subtitle: Text(

                                'Instant hotlines and grounding tools',

                                style: GoogleFonts.inter(

                                  fontSize: 12,

                                  color: AppColors.textSecondary,

                                ),

                              ),

                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),

                              onTap: () {

                                Navigator.pushNamed(context, '/support');

                              },

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 20),



                      // Section 3: Notifications & App Settings

                      Text(

                        'Preferences & Privacy',

                        style: GoogleFonts.inter(

                          fontSize: 14,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                        child: Column(

                          children: [

                            SwitchListTile(

                              activeThumbColor: AppColors.primary,

                              title: Text(

                                'Daily Wellness Notifications',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: AppColors.textPrimary,

                                ),

                              ),

                              value: _notificationsEnabled,

                              onChanged: (val) {

                                setState(() {

                                  _notificationsEnabled = val;

                                });

                              },

                            ),

                            const Divider(height: 1, color: Color(0xFFEBECEF)),

                            ListTile(

                              leading: const Icon(Icons.lock_outline, color: AppColors.primary),

                              title: Text(

                                'Privacy & Encryption Policy',

                                style: GoogleFonts.inter(

                                  fontSize: 14,

                                  fontWeight: FontWeight.w600,

                                  color: AppColors.textPrimary,

                                ),

                              ),

                              trailing: const Icon(Icons.arrow_forward_ios, size: 14),

                              onTap: () {},

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 28),



                      // Log Out Button

                      Center(

                        child: TextButton.icon(

                          onPressed: () {

                            Navigator.pushReplacementNamed(context, '/login');

                          },

                          icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),

                          label: Text(

                            'Log Out',

                            style: GoogleFonts.inter(

                              fontSize: 14,

                              fontWeight: FontWeight.w700,

                              color: Colors.redAccent,

                            ),

                          ),

                        ),

                      ),

                      const SizedBox(height: 24),

                    ],

                  ),

                ),

              ),



              // Taller Bottom Navigation Bar with 5 Tab Icons & Persistent Text Labels

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

                    _buildNavItem(2, Icons.menu_book_outlined, Icons.menu_book, 'Diary', route: '/diary'),

                    _buildNavItem(3, Icons.show_chart_outlined, Icons.show_chart, 'Trends', route: '/monitoring'),

                    _buildNavItem(4, Icons.person_outline, Icons.person, 'Profile'),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

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

