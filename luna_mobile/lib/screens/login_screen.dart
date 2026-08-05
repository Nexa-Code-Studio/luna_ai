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

                      "Welcome back, we've missed you.",

                      textAlign: TextAlign.center,

                      style: GoogleFonts.inter(

                        fontSize: 14,

                        color: AppColors.textSecondary,

                      ),

                    ),

                    const SizedBox(height: 28),

                    // Inputs

                    const CustomPillTextField(

                      hintText: 'Email',

                      prefixIcon: Icons.email_outlined,

                      keyboardType: TextInputType.emailAddress,

                    ),

                    const SizedBox(height: 14),

                    const CustomPillTextField(

                      hintText: 'Password',

                      prefixIcon: Icons.lock_outline,

                      isPassword: true,

                    ),

                    const SizedBox(height: 10),

                    Align(

                      alignment: Alignment.centerRight,

                      child: TextButton(

                        onPressed: () {},

                        style: TextButton.styleFrom(

                          padding: EdgeInsets.zero,

                          minimumSize: Size.zero,

                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,

                        ),

                        child: Text(

                          'Forgot Password?',

                          style: GoogleFonts.inter(

                            fontSize: 13,

                            fontWeight: FontWeight.w600,

                            color: AppColors.primary,

                          ),

                        ),

                      ),

                    ),

                    const SizedBox(height: 20),

                    CustomPillButton(

                      text: 'Login',

                      onPressed: () {

                        Navigator.pushReplacementNamed(context, '/home');

                      },

                    ),

                    const SizedBox(height: 20),

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

                    const SizedBox(height: 20),

                    // Social Buttons

                    Row(

                      children: [

                        SocialPillButton(type: 'google', onPressed: () {}),

                        const SizedBox(width: 12),

                        SocialPillButton(type: 'apple', onPressed: () {}),

                      ],

                    ),

                    const SizedBox(height: 24),

                    // Switch to Register

                    GestureDetector(

                      onTap: () {

                        Navigator.pushReplacementNamed(context, '/register');

                      },

                      child: RichText(

                        text: TextSpan(

                          text: 'New here? ',

                          style: GoogleFonts.inter(

                            fontSize: 14,

                            color: AppColors.textLight,

                          ),

                          children: [

                            TextSpan(

                              text: 'Create an account',

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

