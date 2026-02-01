import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'dart:ui'; // For PointerDeviceKind
import 'package:fitness_gem/theme/app_theme.dart';
import 'views/home_view.dart' as home;
import 'views/onboarding_view.dart';
import 'domain/entities/user_profile.dart';
import 'domain/usecases/user/get_user_profile.dart';
import 'services/firebase_service.dart';
import 'views/external_dashboard_view.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/di/injection.dart'; // Import DI setup
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env
  await dotenv.load(fileName: ".env");

  // Firebase 초기화
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Firebase 서비스 초기화 (익명 로그인 등)
  await FirebaseService().initialize();

  // Initialize dependency injection
  await setupDependencyInjection();

  // 프로필 존재 여부 확인
  final profileResult = await getIt<GetUserProfileUseCase>().execute();
  bool showOnboarding = true;
  profileResult.fold(
    (failure) => debugPrint('Initial profile load failed: ${failure.message}'),
    (profile) => showOnboarding = (profile == null),
  );

  runApp(ProviderScope(child: MainApp(showOnboarding: showOnboarding)));
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
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.mouse,
          PointerDeviceKind.touch,
          PointerDeviceKind.stylus,
          PointerDeviceKind.unknown,
        },
      ),

      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) =>
            showOnboarding ? const OnboardingView() : const home.HomeView(),
        'external_dashboard': (context) => const ExternalDashboardView(),
      },
    );
  }
}
