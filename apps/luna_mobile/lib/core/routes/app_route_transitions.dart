import 'package:flutter/material.dart';

/// Provides custom, hardware-accelerated PageRouteBuilders for Luna Mobile.
class AppRouteTransitions {
  /// 1. Modal / Immersive Route:
  /// Enters by sliding up from bottom with subtle scale-in & fade.
  /// Exits by sliding back down quickly.
  static Route<T> modalSlideUpRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 320),
    Duration reverseDuration = const Duration(milliseconds: 240),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.12),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// 2. Hierarchical Forward/Back Route:
  /// Enters by sliding in from right with fade.
  /// Applies a subtle parallax push-back to the outgoing background page.
  /// Exits by sliding back out to the right.
  static Route<T> horizontalDetailRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    Duration reverseDuration = const Duration(milliseconds: 240),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final forwardCurved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        // Slide in from right for incoming page
        final incomingSlide = Tween<Offset>(
          begin: const Offset(0.22, 0.0),
          end: Offset.zero,
        ).animate(forwardCurved);

        // Subtle parallax push-back for outgoing page
        final outgoingSlide = Tween<Offset>(
          begin: Offset.zero,
          end: const Offset(-0.05, 0.0),
        ).animate(secondaryCurved);

        final incomingFade = Tween<double>(begin: 0.0, end: 1.0).animate(forwardCurved);

        return SlideTransition(
          position: outgoingSlide,
          child: SlideTransition(
            position: incomingSlide,
            child: FadeTransition(
              opacity: incomingFade,
              child: child,
            ),
          ),
        );
      },
    );
  }

  /// 3. Root Context & Auth Shift Route:
  /// Soft cross-fade with subtle depth expansion.
  static Route<T> fadeThroughRoute<T>({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 280),
    Duration reverseDuration = const Duration(milliseconds: 220),
  }) {
    return PageRouteBuilder<T>(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: reverseDuration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
