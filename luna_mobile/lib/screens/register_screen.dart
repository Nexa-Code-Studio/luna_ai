import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/custom_text_field.dart';

import '../widgets/glass_card.dart';



class RegisterScreen extends StatefulWidget {

  const RegisterScreen({super.key});



  @override

  State<RegisterScreen> createState() => _RegisterScreenState();

}



class _RegisterScreenState extends State<RegisterScreen> {

  bool _agreeTerms = false;



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      body: Container(

        width: double.infinity,

        height: double.infinity,

        decoration: const BoxDecoration(

          gradient: LinearGradient(

            colors: [

              Color(0xFFF3F5FF),

              Color(0xFFE9ECFF),

              Color(0xFFF8F9FE),

            ],

            begin: Alignment.topCenter,

            end: Alignment.bottomCenter,

          ),

        ),

        child: SafeArea(

          child: Center(

            child: SingleChildScrollView(

              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),

              child: GlassCard(

                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),

                child: Column(

                  mainAxisSize: MainAxisSize.min,

                  children: [

                    // Brand Logo

                    Image.asset(

                      'assets/images/luna_logo.png',

                      width: 50,

                      height: 50,

                      errorBuilder: (context, error, stackTrace) {

                        return const Icon(

                          Icons.nightlight_round,

                          size: 44,

                          color: AppColors.primary,

                        );

                      },

                    ),

                    const SizedBox(height: 8),

                    Text(

                      'Buat Akun Baru',

                      style: GoogleFonts.inter(

                        fontSize: 22,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textPrimary,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      'Bergabung dengan LUNA dan mulai merawat kesehatan mentalmu',

                      textAlign: TextAlign.center,

                      style: GoogleFonts.inter(

                        fontSize: 13,

                        color: AppColors.textSecondary,

                      ),

                    ),

                    const SizedBox(height: 24),



                    // Full Name Field

                    const CustomPillTextField(

                      hintText: 'Nama Lengkap',

                      prefixIcon: Icons.person_outline,

                    ),

                    const SizedBox(height: 14),



                    // Email Field

                    const CustomPillTextField(

                      hintText: 'Alamat Email',

                      prefixIcon: Icons.email_outlined,

                      keyboardType: TextInputType.emailAddress,

                    ),

                    const SizedBox(height: 14),



                    // Password Field

                    const CustomPillTextField(

                      hintText: 'Kata Sandi',

                      prefixIcon: Icons.lock_outline,

                      isPassword: true,

                    ),

                    const SizedBox(height: 12),



                    // Terms & Conditions Checkbox

                    Row(

                      children: [

                        SizedBox(

                          width: 24,

                          height: 24,

                          child: Checkbox(

                            value: _agreeTerms,

                            activeColor: AppColors.primary,

                            shape: RoundedRectangleBorder(

                              borderRadius: BorderRadius.circular(6),

                            ),

                            onChanged: (val) {

                              setState(() {

                                _agreeTerms = val ?? false;

                              });

                            },

                          ),

                        ),

                        const SizedBox(width: 8),

                        Expanded(

                          child: Text(

                            'Saya menyetujui Syarat & Ketentuan Layanan',

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textSecondary,

                            ),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 20),



                    // Register Button

                    CustomPillButton(

                      text: 'Daftar Akun',

                      onPressed: () {

                        Navigator.pushReplacementNamed(context, '/home');

                      },

                    ),

                    const SizedBox(height: 16),



                    // Or Divider

                    Row(

                      children: [

                        const Expanded(child: Divider(color: Color(0xFFD6DCF5))),

                        Padding(

                          padding: const EdgeInsets.symmetric(horizontal: 12.0),

                          child: Text(

                            'atau daftar dengan',

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textLight,

                            ),

                          ),

                        ),

                        const Expanded(child: Divider(color: Color(0xFFD6DCF5))),

                      ],

                    ),

                    const SizedBox(height: 16),



                    // Social Register Buttons

                    Row(

                      children: [

                        Expanded(
                          child: SocialPillButton(
                            type: 'google',
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SocialPillButton(
                            type: 'apple',
                            onPressed: () {},
                          ),
                        ),

                      ],

                    ),

                    const SizedBox(height: 20),



                    // Login Link Footer

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Text(

                          'Sudah punya akun? ',

                          style: GoogleFonts.inter(

                            fontSize: 13,

                            color: AppColors.textSecondary,

                          ),

                        ),

                        GestureDetector(

                          onTap: () {

                            Navigator.pushReplacementNamed(context, '/login');

                          },

                          child: Text(

                            'Masuk',

                            style: GoogleFonts.inter(

                              fontSize: 13,

                              fontWeight: FontWeight.w700,

                              color: AppColors.primary,

                            ),

                          ),

                        ),

                      ],

                    ),

                  ],

                ),

              ),

            ),

          ),

        ),

      ),

    );

  }

}

