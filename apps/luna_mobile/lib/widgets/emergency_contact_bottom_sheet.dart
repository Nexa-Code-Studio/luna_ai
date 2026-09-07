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

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;



    return ClipRRect(

      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),

        child: Container(

          padding: EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 24.0 + bottomInset),

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

                        color: const Color(0xFFFFDCDD),

                        borderRadius: BorderRadius.circular(14),

                      ),

                      child: const Icon(

                        Icons.contact_phone_outlined,

                        color: Color(0xFFD32F2F),

                        size: 22,

                      ),

                    ),

                    const SizedBox(width: 14),

                    Expanded(

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            'Kontak Darurat Utama',

                            style: GoogleFonts.inter(

                              fontSize: 18,

                              fontWeight: FontWeight.w800,

                              color: AppColors.textPrimary,

                            ),

                          ),

                          Text(

                            'Orang terdekat yang akan dihubungi saat situasi krisis.',

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



                // Field 1: Nama Lengkap Kontak Utama

                Text(

                  'NAMA KONTAK UTAMA',

                  style: GoogleFonts.inter(

                    fontSize: 10,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 6),

                TextField(

                  controller: _nameController,

                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),

                  decoration: InputDecoration(

                    hintText: 'Nama lengkap kontak...',

                    filled: true,

                    fillColor: const Color(0xFFF4F6FB),

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide.none,

                    ),

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                  ),

                ),

                const SizedBox(height: 16),



                // Field 2 & 3: Hubungan & Nomor Telepon

                Row(

                  children: [

                    Expanded(

                      flex: 4,

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            'HUBUNGAN',

                            style: GoogleFonts.inter(

                              fontSize: 10,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textLight,

                              letterSpacing: 0.8,

                            ),

                          ),

                          const SizedBox(height: 6),

                          TextField(

                            controller: _relationController,

                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),

                            decoration: InputDecoration(

                              hintText: 'Ibu / Sahabat...',

                              filled: true,

                              fillColor: const Color(0xFFF4F6FB),

                              border: OutlineInputBorder(

                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide.none,

                              ),

                              contentPadding:

                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

                            ),

                          ),

                        ],

                      ),

                    ),

                    const SizedBox(width: 12),

                    Expanded(

                      flex: 6,

                      child: Column(

                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Text(

                            'NOMOR HANDPHONE',

                            style: GoogleFonts.inter(

                              fontSize: 10,

                              fontWeight: FontWeight.w700,

                              color: AppColors.textLight,

                              letterSpacing: 0.8,

                            ),

                          ),

                          const SizedBox(height: 6),

                          TextField(

                            controller: _phoneController,

                            keyboardType: TextInputType.phone,

                            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),

                            decoration: InputDecoration(

                              hintText: '+62 812-xxxx...',

                              filled: true,

                              fillColor: const Color(0xFFF4F6FB),

                              border: OutlineInputBorder(

                                borderRadius: BorderRadius.circular(14),

                                borderSide: BorderSide.none,

                              ),

                              contentPadding:

                                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),

                            ),

                          ),

                        ],

                      ),

                    ),

                  ],

                ),

                const SizedBox(height: 16),



                // Field 4: Nomor Kontak Sekunder

                Text(

                  'KONTAK SEKUNDER (OPSIONAL)',

                  style: GoogleFonts.inter(

                    fontSize: 10,

                    fontWeight: FontWeight.w700,

                    color: AppColors.textLight,

                    letterSpacing: 0.8,

                  ),

                ),

                const SizedBox(height: 6),

                TextField(

                  controller: _secondaryPhoneController,

                  keyboardType: TextInputType.phone,

                  style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),

                  decoration: InputDecoration(

                    hintText: 'Nomor telepon cadangan...',

                    filled: true,

                    fillColor: const Color(0xFFF4F6FB),

                    border: OutlineInputBorder(

                      borderRadius: BorderRadius.circular(14),

                      borderSide: BorderSide.none,

                    ),

                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),

                  ),

                ),

                const SizedBox(height: 24),



                // Action Buttons: Simpan & Uji Panggilan Darurat

                CustomPillButton(

                  text: 'Simpan Perubahan Kontak',

                  onPressed: () {

                    widget.onSave(

                      _nameController.text.trim(),

                      _relationController.text.trim(),

                      _phoneController.text.trim(),

                    );

                    Navigator.pop(context);

                  },

                ),

                const SizedBox(height: 10),

                CustomPillButton(

                  text: 'Uji Panggilan Darurat',

                  isOutline: true,

                  onPressed: () {

                    ScaffoldMessenger.of(context).showSnackBar(

                      SnackBar(

                        content: Text(

                          'Menghubungi ${_nameController.text.trim()} (${_phoneController.text.trim()})...',

                        ),

                        backgroundColor: const Color(0xFFD32F2F),

                      ),

                    );

                  },

                ),

                const SizedBox(height: 12),

              ],

            ),

          ),

        ),

      ),

    );

  }

}

