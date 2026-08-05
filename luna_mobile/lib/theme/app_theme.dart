import 'package:flutter/material.dart';

import 'app_colors.dart';



class AppTheme {

  static ThemeData get lightTheme {

    return ThemeData(

      useMaterial3: true,

      scaffoldBackgroundColor: AppColors.background,

      colorScheme: const ColorScheme.light(

        primary: AppColors.primary,

        primaryContainer: AppColors.primaryContainer,

        secondary: AppColors.secondary,

        tertiary: AppColors.tertiary,

        surface: AppColors.surface,

      ),

      appBarTheme: const AppBarTheme(

        backgroundColor: Colors.transparent,

        elevation: 0,

        scrolledUnderElevation: 0,

        iconTheme: IconThemeData(color: AppColors.textPrimary),

      ),

    );

  }

}

