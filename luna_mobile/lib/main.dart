import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

import 'screens/splash_onboarding_screen.dart';

import 'screens/login_screen.dart';

import 'screens/register_screen.dart';

import 'screens/home_screen.dart';

import 'screens/ai_conversation_screen.dart';

import 'screens/voice_call_screen.dart';

import 'screens/ai_diary_screen.dart';

import 'screens/monitoring_screen.dart';

import 'screens/recommendation_screen.dart';

import 'screens/support_emergency_screen.dart';



void main() {

  runApp(const LunaApp());

}



class LunaApp extends StatelessWidget {

  const LunaApp({super.key});



  @override

  Widget build(BuildContext context) {

    return MaterialApp(

      title: 'LUNA AI - Mental Health Companion',

      debugShowCheckedModeBanner: false,

      theme: AppTheme.lightTheme,

      initialRoute: '/',

      routes: {

        '/': (context) => const SplashOnboardingScreen(),

        '/login': (context) => const LoginScreen(),

        '/register': (context) => const RegisterScreen(),

        '/home': (context) => const HomeScreen(),

        '/chat': (context) => const AiConversationScreen(),

        '/voice_call': (context) => const VoiceCallScreen(),

        '/diary': (context) => const AiDiaryScreen(),

        '/monitoring': (context) => const MonitoringScreen(),

        '/recommendation': (context) => const RecommendationScreen(),

        '/support': (context) => const SupportEmergencyScreen(),

      },

    );

  }

}

