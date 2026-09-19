import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/ai_conversation_screen.dart';
import 'screens/ai_diary_detail_screen.dart';
import 'screens/ai_diary_screen.dart';
import 'screens/dass_assessment_screen.dart';
import 'screens/emergency_contacts_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/monitoring_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/recommendation_screen.dart';
import 'screens/register_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_onboarding_screen.dart';
import 'screens/support_emergency_screen.dart';
import 'screens/voice_call_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: LunaApp()));
}

class LunaApp extends StatelessWidget {
  const LunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MaterialApp(
        title: 'LUNA AI - Mental Health Companion',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      initialRoute: '/',

      routes: {

        '/': (context) => const SplashOnboardingScreen(),

        '/login': (context) => const LoginScreen(),

        '/register': (context) => const RegisterScreen(),

        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialIndex = (args?['initialIndex'] as int?) ?? 0;
          return MainShellScreen(initialIndex: initialIndex);
        },

        '/chat': (context) => const AiConversationScreen(),

        '/voice_call': (context) => const VoiceCallScreen(),

        '/diary': (context) => const AiDiaryScreen(),

        '/diary_detail': (context) {

          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

          return AiDiaryDetailScreen(journalData: args);

        },

        '/monitoring': (context) => const MonitoringScreen(),
        '/dass_assessment': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
          final initialPeriod = (args?['period'] as String?) ?? 'today';
          return DASSAssessmentScreen(initialPeriod: initialPeriod);
        },
        '/recommendation': (context) => const RecommendationScreen(),

        '/support': (context) => const SupportEmergencyScreen(),

        '/profile': (context) => const ProfileScreen(),

        '/emergency_contacts': (context) => const EmergencyContactsScreen(),

        '/settings': (context) => const SettingsScreen(),

      },
    ),
  );
}

}

