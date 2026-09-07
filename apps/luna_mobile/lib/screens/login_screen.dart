import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';

import '../widgets/custom_button.dart';

import '../widgets/custom_text_field.dart';

import '../widgets/glass_card.dart';



class LoginScreen extends StatelessWidget {

  const LoginScreen({super.key});



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

                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),

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

                      'Selamat Datang Kembali',

                      style: GoogleFonts.inter(

                        fontSize: 22,

                        fontWeight: FontWeight.w700,

                        color: AppColors.textPrimary,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      'Masuk untuk melanjutkan perjalanan ketenanganmu',

                      textAlign: TextAlign.center,

                      style: GoogleFonts.inter(

                        fontSize: 13,

                        color: AppColors.textSecondary,

                      ),

                    ),

                    const SizedBox(height: 28),



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

                    const SizedBox(height: 10),



                    // Forgot Password Link

                    Align(

                      alignment: Alignment.centerRight,

                      child: GestureDetector(

                        onTap: () {},

                        child: Text(

                          'Lupa Kata Sandi?',

                          style: GoogleFonts.inter(

                            fontSize: 12,

                            fontWeight: FontWeight.w600,

                            color: AppColors.primary,

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 24),



                    // Login Button

                    CustomPillButton(

                      text: 'Masuk',

                      onPressed: () {

                        Navigator.pushReplacementNamed(context, '/home');

                      },

                    ),

                    const SizedBox(height: 20),



                    // Or Divider

                    Row(

                      children: [

                        const Expanded(child: Divider(color: Color(0xFFD6DCF5))),

                        Padding(

                          padding: const EdgeInsets.symmetric(horizontal: 12.0),

                          child: Text(

                            'atau masuk dengan',

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              color: AppColors.textLight,

                            ),

                          ),

                        ),

                        const Expanded(child: Divider(color: Color(0xFFD6DCF5))),

                      ],

                    ),

                    const SizedBox(height: 20),



                    // Social Login Buttons Row

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

                    const SizedBox(height: 24),



                    // Register Link Footer

                    Row(

                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        Text(

                          'Belum punya akun? ',

                          style: GoogleFonts.inter(

                            fontSize: 13,

                            color: AppColors.textSecondary,

                          ),

                        ),

                        GestureDetector(

                          onTap: () {

                            Navigator.pushReplacementNamed(context, '/register');

                          },

                          child: Text(

                            'Daftar',

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

