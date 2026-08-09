import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import 'custom_button.dart';



class EmergencyContactBottomSheet extends StatefulWidget {

  final String initialName;

  final String initialRelation;

  final String initialPhone;

  final Function(String name, String relation, String phone) onSave;



  const EmergencyContactBottomSheet({

    super.key,

    required this.initialName,

    required this.initialRelation,

    required this.initialPhone,

    required this.onSave,

  });



  @override

  State<EmergencyContactBottomSheet> createState() => _EmergencyContactBottomSheetState();

}



class _EmergencyContactBottomSheetState extends State<EmergencyContactBottomSheet> {

  late TextEditingController _nameController;

  late TextEditingController _relationController;

  late TextEditingController _phoneController;

  late TextEditingController _secondaryPhoneController;



  @override

  void initState() {

    super.initState();

    _nameController = TextEditingController(text: widget.initialName);

    _relationController = TextEditingController(text: widget.initialRelation);

    _phoneController = TextEditingController(text: widget.initialPhone);

    _secondaryPhoneController = TextEditingController(text: '+62 857-1122-3344');

  }



  @override

  void dispose() {

    _nameController.dispose();

    _relationController.dispose();

    _phoneController.dispose();

    _secondaryPhoneController.dispose();

    super.dispose();

  }



  @override

  Widget build(BuildContext context) {

    return ClipRRect(

      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(

          padding: const EdgeInsets.all(24.0),

          decoration: BoxDecoration(

            color: Colors.white.withValues(alpha: 0.95),

            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

            border: Border.all(

              color: Colors.white.withValues(alpha: 0.8),

              width: 1.5,

            ),

          ),

          child: SingleChildScrollView(

            child: Column(

              mainAxisSize: MainAxisSize.min,

              crossAxisAlignment: CrossAxisAlignment.start,

              children: [

                // Handle Bar

                Center(

                  child: Container(

                    width: 48,

                    height: 5,

                    decoration: BoxDecoration(

                      color: Colors.grey.shade300,

                      borderRadius: BorderRadius.circular(999),

                    ),

                  ),

                ),

                const SizedBox(height: 20),



                // Header Title

                Row(

                  children: [

                    Container(

                      width: 42,

                      height: 42,

                      decoration: BoxDecoration(

                        color: const Color(0xFFFFEADB),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Icon(

                        Icons.phone_outlined,

                        color: Color(0xFFE65100),

                        size: 22,

                      ),

                    ),

                    const SizedBox(width: 14),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            'Pengaturan Kontak Darurat',

                            style: GoogleFonts.inter(

                              fontSize: 18,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          Text(

                            'Kelola orang terpercaya saat berada dalam situasi krisis.',

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

                const SizedBox(height: 24),



                // 1. Primary Emergency Contact Section

                Text(

                  'KONTAK UTAMA (PRIORITAS 1)',

                  style: GoogleFonts.inter(

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 10),

                _buildInputField(

                  label: 'Nama Lengkap Kontak',

                  controller: _nameController,

                  icon: Icons.person_outline,

                ),

                const SizedBox(height: 10),

                Row(

                  children: [

                    Expanded(

                      child: _buildInputField(

                        label: 'Hubungan',

                        controller: _relationController,

                        icon: Icons.family_restroom_outlined,

                      ),

                    ),

                    const SizedBox(width: 10),

                    Expanded(

                      flex: 2,

                      child: _buildInputField(

                        label: 'Nomor Telepon / WA',

                        controller: _phoneController,

                        icon: Icons.phone_android_outlined,

                        keyboardType: TextInputType.phone,

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 20),



                // 2. Secondary Emergency Contact Section

                Text(

                  'KONTAK SEKUNDER (OPSIONAL)',

                  style: GoogleFonts.inter(

                    fontSize: 11,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 10),

                _buildInputField(

                  label: 'Nomor Telepon Kontak Ke-2',

                  controller: _secondaryPhoneController,

                  icon: Icons.phone_forwarded_outlined,

                  keyboardType: TextInputType.phone,

                ),

                const SizedBox(height: 20),



                // 3. Test Call Button

                OutlinedButton.icon(

                  onPressed: () {

                    ScaffoldMessenger.of(context).showSnackBar(

                      SnackBar(

                        content: Text(

                          'Simulasi panggilan darurat ke ${_phoneController.text}...',

                          style: GoogleFonts.inter(),

                        ),

                        backgroundColor: AppColors.primary,

                        behavior: SnackBarBehavior.floating,

                      ),

                    );

                  },

                  style: OutlinedButton.styleFrom(

                    foregroundColor: const Color(0xFFE65100),

                    side: const BorderSide(color: Color(0xFFE65100), width: 1.2),

                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),

                    minimumSize: const Size(double.infinity, 46),

                  ),

                  icon: const Icon(Icons.ring_volume, size: 18),

                  label: Text(

                    'Uji Panggilan Darurat',

                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),

                  ),

                ),

                const SizedBox(height: 24),



                // 4. Save Button

                CustomPillButton(

                  text: 'Simpan Kontak Darurat',

                  onPressed: () {

                    widget.onSave(

                      _nameController.text.trim(),

                      _relationController.text.trim(),

                      _phoneController.text.trim(),

                    );

                    Navigator.pop(context);

                  },

                ),

                const SizedBox(height: 16),

              ],

            ),

          ),

        ),

      ),

    );

  }



  Widget _buildInputField({

    required String label,

    required TextEditingController controller,

    required IconData icon,

    TextInputType keyboardType = TextInputType.text,

  }) {

    return Container(

      decoration: BoxDecoration(

        color: const Color(0xFFF4F6FF),

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: Colors.grey.shade300),

      ),

      child: TextField(

        controller: controller,

        keyboardType: keyboardType,

        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),

        decoration: InputDecoration(

          prefixIcon: Icon(icon, size: 18, color: AppColors.primary),

          labelText: label,

          labelStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),

          border: InputBorder.none,

          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

        ),

      ),

    );

  }

}

