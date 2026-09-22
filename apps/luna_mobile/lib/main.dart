import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/routes/app_router.dart';
import 'theme/app_theme.dart';
import 'widgets/web_phone_frame_wrapper.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Asynchronously pre-warm Inter font cache to prevent frame drop on initial screen render
  GoogleFonts.pendingFonts([
    GoogleFonts.inter(),
  ]);
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
        onGenerateRoute: AppRouter.onGenerateRoute,
        builder: (context, child) {
          return WebPhoneFrameWrapper(
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
