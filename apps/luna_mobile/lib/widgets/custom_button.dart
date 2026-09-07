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

          padding: const EdgeInsets.symmetric(horizontal: 12),

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

            Flexible(

              child: Text(

                text,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                textAlign: TextAlign.center,

                style: GoogleFonts.inter(

                  fontSize: 14,

                  fontWeight: FontWeight.w600,

                  color: isOutline ? AppColors.primary : Colors.white,

                ),

              ),

            ),

            if (suffixIcon != null) ...[

              const SizedBox(width: 8),

              Icon(

                suffixIcon,

                size: 20,

                color: isOutline ? AppColors.primary : Colors.white,

              ),

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

    final label = isGoogle ? 'Google' : 'Apple';

    final iconData = isGoogle ? Icons.g_mobiledata : Icons.apple;



    return SizedBox(

      height: 50,

      child: OutlinedButton(

        onPressed: onPressed,

        style: OutlinedButton.styleFrom(

          backgroundColor: Colors.white,

          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),

          shape: RoundedRectangleBorder(

            borderRadius: BorderRadius.circular(999),

          ),

        ),

        child: Row(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            Icon(iconData, color: AppColors.textPrimary, size: isGoogle ? 28 : 22),

            const SizedBox(width: 6),

            Flexible(

              child: Text(

                label,

                maxLines: 1,

                overflow: TextOverflow.ellipsis,

                style: GoogleFonts.inter(

                  fontSize: 14,

                  fontWeight: FontWeight.w600,

                  color: AppColors.textPrimary,

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }

}

