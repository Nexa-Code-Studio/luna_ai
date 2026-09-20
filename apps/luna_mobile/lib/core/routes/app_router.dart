import 'package:flutter/material.dart';

import '../../screens/ai_conversation_screen.dart';
import '../../screens/ai_diary_detail_screen.dart';
import '../../screens/ai_diary_screen.dart';
import '../../screens/dass_assessment_screen.dart';
import '../../screens/emergency_contacts_screen.dart';
import '../../screens/login_screen.dart';
import '../../screens/main_shell_screen.dart';
import '../../screens/monitoring_screen.dart';
import '../../screens/profile_screen.dart';
import '../../screens/recommendation_screen.dart';
import '../../screens/register_screen.dart';
import '../../screens/settings_screen.dart';
import '../../screens/splash_onboarding_screen.dart';
import '../../screens/support_emergency_screen.dart';
import '../../screens/terms_disclaimer_screen.dart';
import '../../screens/voice_call_screen.dart';
import '../../screens/voice_session_detail_screen.dart';
import 'app_route_transitions.dart';

/// Centralized route generator applying custom transitions to all Luna Mobile pages.
class AppRouter {
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name;
    final args = settings.arguments as Map<String, dynamic>?;

    switch (name) {
      // 1. Root Context & Auth Shift (fadeThroughRoute)
      case '/':
        return AppRouteTransitions.fadeThroughRoute(
          page: const SplashOnboardingScreen(),
          settings: settings,
        );
      case '/login':
        return AppRouteTransitions.fadeThroughRoute(
          page: const LoginScreen(),
          settings: settings,
        );
      case '/register':
        return AppRouteTransitions.fadeThroughRoute(
          page: const RegisterScreen(),
          settings: settings,
        );
      case '/home':
        final initialIndex = (args?['initialIndex'] as int?) ?? 0;
        return AppRouteTransitions.fadeThroughRoute(
          page: MainShellScreen(initialIndex: initialIndex),
          settings: settings,
        );
      case '/diary':
        return AppRouteTransitions.fadeThroughRoute(
          page: const AiDiaryScreen(),
          settings: settings,
        );
      case '/monitoring':
        return AppRouteTransitions.fadeThroughRoute(
          page: const MonitoringScreen(),
          settings: settings,
        );
      case '/profile':
        return AppRouteTransitions.fadeThroughRoute(
          page: const ProfileScreen(),
          settings: settings,
        );

      // 2. Modal / Immersive Experience (modalSlideUpRoute)
      case '/chat':
        return AppRouteTransitions.modalSlideUpRoute(
          page: const AiConversationScreen(),
          settings: settings,
        );
      case '/voice_call':
      case '/call':
        return AppRouteTransitions.modalSlideUpRoute(
          page: const VoiceCallScreen(),
          settings: settings,
        );
      case '/support':
      case '/support_emergency':
        return AppRouteTransitions.modalSlideUpRoute(
          page: const SupportEmergencyScreen(),
          settings: settings,
        );
      case '/dass_assessment':
      case '/dass':
        final initialPeriod = (args?['period'] as String?) ?? 'today';
        return AppRouteTransitions.modalSlideUpRoute(
          page: DASSAssessmentScreen(initialPeriod: initialPeriod),
          settings: settings,
        );

      // 3. Hierarchical Forward/Back (horizontalDetailRoute)
      case '/diary_detail':
        return AppRouteTransitions.horizontalDetailRoute(
          page: AiDiaryDetailScreen(journalData: args),
          settings: settings,
        );
      case '/voice_session_detail':
        return AppRouteTransitions.horizontalDetailRoute(
          page: VoiceSessionDetailScreen(sessionData: args),
          settings: settings,
        );
      case '/emergency_contacts':
        return AppRouteTransitions.horizontalDetailRoute(
          page: const EmergencyContactsScreen(),
          settings: settings,
        );
      case '/settings':
        return AppRouteTransitions.horizontalDetailRoute(
          page: const SettingsScreen(),
          settings: settings,
        );
      case '/recommendation':
        return AppRouteTransitions.horizontalDetailRoute(
          page: const RecommendationScreen(),
          settings: settings,
        );
      case '/terms_disclaimer':
        return AppRouteTransitions.horizontalDetailRoute(
          page: const TermsDisclaimerScreen(),
          settings: settings,
        );

      default:
        return null;
    }
  }
}
