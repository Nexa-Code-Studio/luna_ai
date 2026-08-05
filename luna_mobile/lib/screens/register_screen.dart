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

                      'LUNA',

                      style: GoogleFonts.inter(

                        fontSize: 22,

                        fontWeight: FontWeight.w800,

                        color: AppColors.primary,

                        letterSpacing: 1.2,

                      ),

                    ),

                    const SizedBox(height: 6),

                    Text(

                      'Join a community dedicated to your wellbeing.',

                      textAlign: TextAlign.center,

                      style: GoogleFonts.inter(

                        fontSize: 14,

                        color: AppColors.textSecondary,

                      ),

                    ),

                    const SizedBox(height: 24),

                    // Inputs

                    const CustomPillTextField(

                      hintText: 'Full Name',

                      prefixIcon: Icons.person_outline,

                    ),

                    const SizedBox(height: 12),

                    const CustomPillTextField(

                      hintText: 'Email',

                      prefixIcon: Icons.email_outlined,

                      keyboardType: TextInputType.emailAddress,

                    ),

                    const SizedBox(height: 12),

                    const CustomPillTextField(

                      hintText: 'Password',

                      prefixIcon: Icons.lock_outline,

                      isPassword: true,

                    ),

                    const SizedBox(height: 12),

                    // Terms Checkbox

                    Row(

                      children: [

                        SizedBox(

                          width: 24,

                          height: 24,

                          child: Checkbox(

                            value: _agreeTerms,

                            activeColor: AppColors.primary,

                            shape: const CircleBorder(),

                            onChanged: (val) {

                              setState(() {

                                _agreeTerms = val ?? false;

                              });

                            },

                          ),

                        ),

                        const SizedBox(width: 8),

                        Expanded(

                          child: RichText(

                            text: TextSpan(

                              text: 'I agree to the ',

                              style: GoogleFonts.inter(

                                fontSize: 12,

                                color: AppColors.textSecondary,

                              ),

                              children: [

                                TextSpan(

                                  text: 'Terms',

                                  style: GoogleFonts.inter(

                                    fontWeight: FontWeight.w600,

                                    color: AppColors.primary,

                                  ),

                                ),

                                const TextSpan(text: ' and '),

                                TextSpan(

                                  text: 'Privacy Policy',

                                  style: GoogleFonts.inter(

                                    fontWeight: FontWeight.w600,

                                    color: AppColors.primary,

                                  ),

                                ),

                                const TextSpan(text: '.'),

                              ],

                            ),

                          ),

                        ),

                      ],

                    ),

                    const SizedBox(height: 20),

                    CustomPillButton(

                      text: 'Create Account',

                      onPressed: () {

                        Navigator.pushReplacementNamed(context, '/home');

                      },

                    ),

                    const SizedBox(height: 18),

                    // Divider

                    Row(

                      children: [

                        Expanded(child: Divider(color: Colors.grey.shade300)),

                        Padding(

                          padding: const EdgeInsets.symmetric(horizontal: 12),

                          child: Text(

                            'OR',

                            style: GoogleFonts.inter(

                              fontSize: 12,

                              fontWeight: FontWeight.w600,

                              color: AppColors.textLight,

                            ),

                          ),

                        ),

                        Expanded(child: Divider(color: Colors.grey.shade300)),

                      ],

                    ),

                    const SizedBox(height: 18),

                    // Social Buttons

                    Row(

                      children: [

                        SocialPillButton(type: 'google', onPressed: () {}),

                        const SizedBox(width: 12),

                        SocialPillButton(type: 'apple', onPressed: () {}),

                      ],

                    ),

                    const SizedBox(height: 20),

                    // Switch to Login

                    GestureDetector(

                      onTap: () {

                        Navigator.pushReplacementNamed(context, '/login');

                      },

                      child: RichText(

                        text: TextSpan(

                          text: 'Already have an account? ',

                          style: GoogleFonts.inter(

                            fontSize: 14,

                            color: AppColors.textLight,

                          ),

                          children: [

                            TextSpan(

                              text: 'Log in',

                              style: GoogleFonts.inter(

                                fontSize: 14,

                                fontWeight: FontWeight.w600,

                                color: AppColors.primary,

                              ),

                            ),

                          ],

                        ),

                      ),

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

