import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'views/home_view.dart';
import 'views/onboarding_view.dart';
import 'models/user_profile.dart';
import 'services/firebase_service.dart';
import 'views/external_dashboard_view.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase 서비스 초기화 (익명 로그인 등)
  await FirebaseService().initialize();

  // 프로필 존재 여부 확인
  final profile = await UserProfile.load();
  final bool showOnboarding = profile == null;

  runApp(MainApp(showOnboarding: showOnboarding));
}

class MainApp extends StatelessWidget {
  final bool showOnboarding;

  const MainApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fitness Gem',

      // Localization
      locale: const Locale('en'), // Default to English
      supportedLocales: const [
        Locale('en'), // English (default)
        Locale('ko'), // Korean
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.dark(
          primary: Colors.deepPurple,
          secondary: Colors.deepPurpleAccent,
          surface: Colors.grey[900]!,
        ),
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: const CardThemeData(
          color: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        useMaterial3: true,
      ),
      home: showOnboarding ? const OnboardingView() : const HomeView(),
      routes: {
        'external_dashboard': (context) => const ExternalDashboardView(),
      },
    );
  }
}
