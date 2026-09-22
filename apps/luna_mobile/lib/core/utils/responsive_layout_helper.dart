import 'package:flutter/material.dart';

/// Extension providing responsive layout and typography utilities across Luna Mobile.
extension ResponsiveLayoutExtension on BuildContext {
  /// Responsive font scale factor clamped between 0.85 (compact devices ~320-360px)
  /// and 1.10 (large phones / tablets). Baseline standard viewport width is 390px.
  double get fontScale {
    final width = MediaQuery.sizeOf(this).width;
    return (width / 390.0).clamp(0.85, 1.10);
  }

  /// Calculates a scaled font size based on the current screen width.
  double responsiveFont(double baseSize) {
    return (baseSize * fontScale).roundToDouble();
  }
}
