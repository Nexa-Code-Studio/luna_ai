import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/floating_nav_bar.dart';

import '../widgets/glass_card.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  int _currentIndex = 3; // Profil tab selected



  bool _memoryEnabled = true;

  bool _notificationsEnabled = true;



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

                          'Profil & Pengaturan',

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



                  // Scrollable Content

                  Expanded(

                    child: SingleChildScrollView(

                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

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

                                          'Anggota Pendamping LUNA',

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



                          // Section 1: Memori Jangka Panjang AI

                          Text(

                            'Memori Jangka Panjang AI',

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

                                    'Aktifkan Memori Jangka Panjang',

                                    style: GoogleFonts.inter(

                                      fontSize: 14,

                                      fontWeight: FontWeight.w600,

                                      color: AppColors.textPrimary,

                                    ),

                                  ),

                                  subtitle: Text(

                                    'Mengizinkan LUNA mengingat ritem emosi & target pribadimu',

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

                                    'Hapus Catatan Memori AI',

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



                          // Section 2: Kontak Darurat & Rencana Krisis

                          Text(

                            'Rencana Keselamatan Krisis',

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

                                    'Kontak Darurat Utama',

                                    style: GoogleFonts.inter(

                                      fontSize: 14,

                                      fontWeight: FontWeight.w600,

                                      color: AppColors.textPrimary,

                                    ),

                                  ),

                                  subtitle: Text(

                                    'Ibu (+62 812-3456-7890)',

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

                                    'Buka Pusat Bantuan Krisis',

                                    style: GoogleFonts.inter(

                                      fontSize: 14,

                                      fontWeight: FontWeight.w600,

                                      color: AppColors.textPrimary,

                                    ),

                                  ),

                                  subtitle: Text(

                                    'Akses cepat hotline & bantuan darurat',

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



                          // Section 3: Pengaturan & Privasi

                          Text(

                            'Preferensi & Privasi',

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

                                    'Notifikasi Pengingat Harian',

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

                                    'Kebijakan Privasi & Enkripsi Data',

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

                                'Keluar Akun',

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

}

