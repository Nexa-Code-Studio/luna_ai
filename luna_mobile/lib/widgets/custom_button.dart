import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';



class CustomPillButton extends StatelessWidget {

  final String text;

  final VoidCallback onPressed;

  final bool isOutline;

  final IconData? suffixIcon;

  final double height;



  const CustomPillButton({

    super.key,

    required this.text,

    required this.onPressed,

    this.isOutline = false,

    this.suffixIcon,

    this.height = 54.0,

  });



  @override

  Widget build(BuildContext context) {

    return SizedBox(

      width: double.infinity,

      height: height,

      child: ElevatedButton(

        onPressed: onPressed,

        style: ElevatedButton.styleFrom(

          backgroundColor: isOutline ? Colors.transparent : AppColors.primary,

          foregroundColor: isOutline ? AppColors.primary : Colors.white,

          elevation: isOutline ? 0 : 4,

          shadowColor: AppColors.primary.withValues(alpha: 0.3),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(999),

            side: isOutline

                ? const BorderSide(color: AppColors.primary, width: 1.5)

                : BorderSide.none,

          ),

        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Text(

              text,

              style: GoogleFonts.inter(

                fontSize: 16,

                fontWeight: FontWeight.w600,

                color: isOutline ? AppColors.primary : Colors.white,

              ),

            ),

            if (suffixIcon != null) ...[

              const SizedBox(width: 8),

              Icon(suffixIcon, size: 20),

            ],

          ],

        ),

      ),

    );

  }

}



class SocialPillButton extends StatelessWidget {

  final String type; // 'google' or 'apple'

  final VoidCallback onPressed;



  const SocialPillButton({

    super.key,

    required this.type,

    required this.onPressed,

  });



  @override

  Widget build(BuildContext context) {

    final isGoogle = type == 'google';

    return Expanded(

      child: SizedBox(

        height: 52,

        child: OutlinedButton(

          onPressed: onPressed,

          style: OutlinedButton.styleFrom(

            backgroundColor: Colors.white,

            side: BorderSide(color: Colors.grey.shade300, width: 1),

            shape: RoundedRectangleBorder(

              borderRadius: BorderRadius.circular(999),

            ),

          ),

          child: isGoogle

              ? Row(

                  mainAxisAlignment: MainAxisAlignment.center,

                  children: [

                    Text(

                      'G',

                      style: GoogleFonts.inter(

                        fontSize: 22,

                        fontWeight: FontWeight.w700,

                        color: const Color(0xFF4285F4),

                      ),

                    ),

                  ],

                )

              : const Icon(

                  Icons.apple,

                  color: Colors.black,

                  size: 26,

                ),

        ),

      ),

    );

  }

}

