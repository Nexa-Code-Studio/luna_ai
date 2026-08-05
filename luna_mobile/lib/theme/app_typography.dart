import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';



class AppTypography {

  static TextStyle displayLarge = GoogleFonts.inter(

    fontSize: 28,

    fontWeight: FontWeight.w700,

    color: AppColors.textPrimary,

    height: 1.3,

  );



  static TextStyle headlineMedium = GoogleFonts.inter(

    fontSize: 22,

    fontWeight: FontWeight.w700,

    color: AppColors.textPrimary,

    height: 1.3,

  );



  static TextStyle titleMedium = GoogleFonts.inter(

    fontSize: 16,

    fontWeight: FontWeight.w600,

    color: AppColors.textPrimary,

    height: 1.4,

  );



  static TextStyle bodyLarge = GoogleFonts.inter(

    fontSize: 15,

    fontWeight: FontWeight.w400,

    color: AppColors.textSecondary,

    height: 1.5,

  );



  static TextStyle bodyMedium = GoogleFonts.inter(

    fontSize: 14,

    fontWeight: FontWeight.w400,

    color: AppColors.textSecondary,

    height: 1.5,

  );



  static TextStyle labelSmall = GoogleFonts.inter(

    fontSize: 12,

    fontWeight: FontWeight.w600,

    color: AppColors.textLight,

    letterSpacing: 0.5,

  );



  static TextStyle buttonText = GoogleFonts.inter(

    fontSize: 16,

    fontWeight: FontWeight.w600,

    color: Colors.white,

  );

}

