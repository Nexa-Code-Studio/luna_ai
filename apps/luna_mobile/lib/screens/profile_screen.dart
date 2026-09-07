import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/glass_card.dart';



class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});



  @override

  State<ProfileScreen> createState() => _ProfileScreenState();

}



class _ProfileScreenState extends State<ProfileScreen> {

  final String _emergencyContactName = 'Budi Utami (Ibu)';

  final String _emergencyContactPhone = '+62 812-3456-7890';



  void _showDeleteMemoryConfirmationDialog() {

    showDialog(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),

          title: Row(

            children: [

              Container(

                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(

                  color: const Color(0xFFFFDCDD),

                  borderRadius: BorderRadius.circular(12),

                ),

                child: const Icon(

                  Icons.warning_amber_rounded,

                  color: Color(0xFFD32F2F),

                  size: 22,

                ),

              ),

              const SizedBox(width: 10),

              Expanded(

                child: Text(

                  'Hapus Memori AI?',

                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),

                ),

              ),

            ],

          ),

          content: Text(

            'Apakah Anda yakin ingin menghapus seluruh catatan memori AI? LUNA akan menghapus riwayat konteks emosional yang telah dipelajari.',

            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),

          ),

          actions: [

            TextButton(

              onPressed: () => Navigator.pop(context),

              child: Text(

                'Batal',

                style: GoogleFonts.inter(color: AppColors.textSecondary),

              ),

            ),

            ElevatedButton(

              style: ElevatedButton.styleFrom(

                backgroundColor: const Color(0xFFD32F2F),

                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),

              ),

              onPressed: () {

                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(

                  const SnackBar(

                    content: Text('Seluruh catatan memori AI telah berhasil dihapus.'),

                    backgroundColor: Color(0xFFD32F2F),

                  ),

                );

              },

              child: Text(

                'Ya, Hapus Memori',

                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),

              ),

            ),

          ],

        );

      },

    );

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

          child: Column(

            children: [

              // Header Bar with Brand Title LUNA & Settings Icon

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

                      icon: const Icon(Icons.settings_outlined),

                      color: AppColors.primary,

                      onPressed: () {},

                    ),

                  ],

                ),

              ),



              // Scrollable Content Body

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      // User Profile Header Glass Card

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(20),

                        child: Row(

                          children: [

                            Container(

                              width: 60,

                              height: 60,

                              decoration: const BoxDecoration(

                                shape: BoxShape.circle,

                                gradient: LinearGradient(

                                  colors: [Color(0xFF8B93FF), Color(0xFF5358CB)],

                                ),

                              ),

                              child: const Center(

                                child: Text(

                                  'SJ',

                                  style: TextStyle(

                                    fontSize: 20,

                                    fontWeight: FontWeight.bold,

                                    color: Colors.white,

                                  ),

                                ),

                              ),

                            ),

                            const SizedBox(width: 16),

                            Expanded(

                              child: Column(

                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: [

                                  Text(

                                    'Sarah Jenkins',

                                    maxLines: 1,

                                    overflow: TextOverflow.ellipsis,

                                    style: GoogleFonts.inter(

                                      fontSize: 18,

                                      fontWeight: FontWeight.w800,

                                      color: AppColors.textPrimary,

                                    ),

                                  ),

                                  const SizedBox(height: 2),

                                  Text(

                                    'sarah.jenkins@example.com',

                                    maxLines: 1,

                                    overflow: TextOverflow.ellipsis,

                                    style: GoogleFonts.inter(

                                      fontSize: 13,

                                      color: AppColors.textSecondary,

                                    ),

                                  ),

                                  const SizedBox(height: 6),

                                  Container(

                                    padding: const EdgeInsets.symmetric(

                                      horizontal: 10,

                                      vertical: 3,

                                    ),

                                    decoration: BoxDecoration(

                                      color: AppColors.primaryContainer,

                                      borderRadius: BorderRadius.circular(999),

                                    ),

                                    child: Text(

                                      'ANGGOTA PREMIUM',

                                      style: GoogleFonts.inter(

                                        fontSize: 9,

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

                      const SizedBox(height: 24),



                      // Section 1: AI & PRIVASI (No Toggle ON, Only Delete Button)

                      Text(

                        'AI & PRIVASI MEMORI',

                        style: GoogleFonts.inter(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.all(16),

                        child: Column(

                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [

                            Row(

                              children: [

                                Container(

                                  width: 36,

                                  height: 36,

                                  decoration: BoxDecoration(

                                    color: const Color(0xFFE2DAFF),

                                    borderRadius: BorderRadius.circular(12),

                                  ),

                                  child: const Icon(

                                    Icons.psychology_outlined,

                                    color: AppColors.primary,

                                    size: 20,

                                  ),

                                ),

                                const SizedBox(width: 12),

                                Expanded(

                                  child: Column(

                                    crossAxisAlignment: CrossAxisAlignment.start,

                                    children: [

                                      Text(

                                        'Memori Jangka Panjang AI',

                                        style: GoogleFonts.inter(

                                          fontSize: 14,

                                          fontWeight: FontWeight.w700,

                                          color: AppColors.textPrimary,

                                        ),

                                      ),

                                      Text(

                                        'LUNA menyimpan konteks emosional harianmu.',

                                        style: GoogleFonts.inter(

                                          fontSize: 12,

                                          color: AppColors.textSecondary,

                                        ),

                                      ),

                                    ],

                                  ),

                                ),

                              ],

                            ),

                            const SizedBox(height: 14),

                            CustomPillButton(

                              text: 'Hapus Catatan Memori AI',

                              isOutline: true,

                              height: 44,

                              onPressed: _showDeleteMemoryConfirmationDialog,

                            ),

                          ],

                        ),

                      ),

                      const SizedBox(height: 24),



                      // Section 2: RENCANA KESELAMATAN KRISIS

                      Text(

                        'RENCANA KESELAMATAN KRISIS',

                        style: GoogleFonts.inter(

                          fontSize: 11,

                          fontWeight: FontWeight.w700,

                          color: AppColors.textLight,

                          letterSpacing: 0.8,

                        ),

                      ),

                      const SizedBox(height: 10),

                      GlassCard(

                        width: double.infinity,

                        padding: const EdgeInsets.symmetric(vertical: 4),

                        child: ListTile(

                          leading: Container(

                            width: 36,

                            height: 36,

                            decoration: BoxDecoration(

                              color: const Color(0xFFFFDCDD),

                              borderRadius: BorderRadius.circular(12),

                            ),

                            child: const Icon(

                              Icons.contact_phone_outlined,

                              color: Color(0xFFD32F2F),

                              size: 20,

                            ),

                          ),

                          title: Text(

                            'Kontak Darurat Utama',

                            style: GoogleFonts.inter(

                              fontSize: 14,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          subtitle: Text(

                            '$_emergencyContactName • $_emergencyContactPhone',

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textSecondary,

                            ),

                          ),

                          trailing: const Icon(

                            Icons.arrow_forward_ios,

                            size: 16,

                            color: AppColors.textLight,

                          ),

                          onTap: () async {

                            await Navigator.pushNamed(context, '/emergency_contacts');

                          },

                        ),

                      ),

                      const SizedBox(height: 36),



                      // Red Outlined Logout Pill Button

                      SizedBox(

                        width: double.infinity,

                        height: 52,

                        child: OutlinedButton.icon(

                          onPressed: () {

                            Navigator.pushReplacementNamed(context, '/login');

                          },

                          style: OutlinedButton.styleFrom(

                            side: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(999),

                            ),

                            backgroundColor: Colors.transparent,

                          ),

                          icon: const Icon(

                            Icons.logout,

                            color: Color(0xFFD32F2F),

                            size: 20,

                          ),

                          label: Text(

                            'Keluar Akun',

                            style: GoogleFonts.inter(

                              fontSize: 15,

                              fontWeight: FontWeight.w700,

                              color: const Color(0xFFD32F2F),

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

        ),

      ),

    );

  }

}

