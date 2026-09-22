import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Wraps the application inside a sleek, modern smartphone frame when viewed on
/// desktop/wide web browsers (width > 500px).
/// 
/// When opened on mobile devices or narrow viewports (width <= 500px), or in native mobile builds,
/// it seamlessly renders full-screen without any outer frame.
class WebPhoneFrameWrapper extends StatelessWidget {
  final Widget child;

  const WebPhoneFrameWrapper({
    super.key,
    required this.child,
  });

  static const double maxPhoneWidth = 420.0;
  static const double maxPhoneHeight = 900.0;
  static const double breakpointWidth = 500.0;

  @override
  Widget build(BuildContext context) {
    // On native mobile builds (Android/iOS APK), never wrap with desktop frame
    if (!kIsWeb) {
      return child;
    }

    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final screenHeight = mediaQuery.size.height;

    // On mobile web browser (e.g. mobile Safari / Chrome on Android), render full-screen directly
    if (screenWidth <= breakpointWidth) {
      return child;
    }

    // Desktop/Tablet Web View: Center within a premium modern phone mockup frame
    final double phoneWidth = math.min(screenWidth - 48.0, maxPhoneWidth);
    final double phoneHeight = math.min(screenHeight - 56.0, maxPhoneHeight);

    return Scaffold(
      backgroundColor: const Color(0xFF0C0A14),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Ambient atmospheric glow in desktop background
          Positioned(
            top: screenHeight * 0.15,
            left: (screenWidth / 2) - 260,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.14),
                    const Color(0xFFA855F7).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

          // 2. Top-left branding pill on desktop browser
          Positioned(
            top: 20,
            left: 28,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Luna AI • Mobile Web Simulator',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Central Smartphone Frame
          Center(
            child: Container(
              width: phoneWidth,
              height: phoneHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(46.0),
                border: Border.all(
                  color: const Color(0xFF262438),
                  width: 10.0,
                ),
                boxShadow: [
                  // Deep atmospheric elevation shadow
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.70),
                    blurRadius: 48,
                    spreadRadius: 4,
                    offset: const Offset(0, 16),
                  ),
                  // Outer subtle violet bezel illumination
                  BoxShadow(
                    color: const Color(0xFF818CF8).withValues(alpha: 0.20),
                    blurRadius: 32,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(36.0),
                child: Stack(
                  children: [
                    // Inner application content with overridden phone-sized MediaQuery
                    Positioned.fill(
                      child: MediaQuery(
                        data: mediaQuery.copyWith(
                          size: Size(phoneWidth, phoneHeight),
                          padding: const EdgeInsets.only(top: 28, bottom: 20),
                          viewPadding: const EdgeInsets.only(top: 28, bottom: 20),
                        ),
                        child: child,
                      ),
                    ),

                    // Top Dynamic Island / Camera Pill Mockup
                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: 96,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF1E1B4B).withValues(alpha: 0.8),
                                  border: Border.all(
                                    color: const Color(0xFF38BDF8).withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Bottom Home Gesture Indicator Line
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Container(
                          width: 120,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
