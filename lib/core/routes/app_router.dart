import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import 'package:lanspeech/core/theme/app_theme.dart';
import 'package:lanspeech/core/services/notification_service.dart';
import 'package:lanspeech/core/services/preferences_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/auth/views/login_screen.dart';
import 'package:lanspeech/features/auth/views/splash_screen.dart';
import 'package:lanspeech/features/onboarding/views/onboarding_screen.dart';
import 'package:lanspeech/features/auth/views/register_screen.dart';
import 'package:lanspeech/features/auth/views/forgot_password_screen.dart';
import 'package:lanspeech/features/dashboard/views/dashboard_screen.dart';
import 'package:lanspeech/features/dashboard/views/practice_placeholder_screen.dart';
import 'package:lanspeech/features/curriculum/views/exercise_player_screen.dart';
import 'package:lanspeech/features/profile/views/premium_upgrade_screen.dart';

String _normalizeSupabaseUrl(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';

  final withoutTrailingSlash = trimmed.replaceAll(RegExp(r'/+$'), '');
  return withoutTrailingSlash.replaceAll(RegExp(r'/rest/v1/?$'), '');
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/practice',
        builder: (context, state) => const PracticePlaceholderScreen(),
      ),
      GoRoute(
        path: '/practice/:chapterNumber/:exerciseNumber',
        builder: (context, state) {
          final chapterNumber =
              int.tryParse(state.pathParameters['chapterNumber'] ?? '') ?? 1;
          final exerciseNumber =
              int.tryParse(state.pathParameters['exerciseNumber'] ?? '') ?? 1;
          return ExercisePlayerScreen(
            chapterNumber: chapterNumber,
            exerciseNumber: exerciseNumber,
          );
        },
      ),
      GoRoute(
        path: '/premium-upgrade',
        builder: (context, state) => const PremiumUpgradeScreen(),
      ),
    ],
  );
});

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: 'config/.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Ignore missing env files; the app falls back to compile-time values.
    }
  }

  final sharedPreferences = await SharedPreferences.getInstance();
  final rawSupabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment(
        'SUPABASE_URL',
        defaultValue: 'https://yfckpzqopanxjznenyvf.supabase.co',
      );
  final supabaseUrl = _normalizeSupabaseUrl(rawSupabaseUrl);

  final supabasePublishableKey = dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ??
      const String.fromEnvironment(
        'SUPABASE_PUBLISHABLE_KEY',
        defaultValue: 'sb_publishable_XIk7d_IQNzNou3ziRcVNNw_sN_O2UqO',
      );

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw StateError(
      'Supabase URL is missing or invalid. Check config/.env and use the project URL (not /rest/v1).',
    );
  }

  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );

  try {
    final notificationService = NotificationService();
    final preferencesService = PreferencesService(sharedPreferences);
    await notificationService.initialize();
    if (preferencesService.isOnboardingCompleted()) {
      final reminderTime = preferencesService.getReminderTime();
      if (reminderTime != null) {
        await notificationService.scheduleDailyReminder(reminderTime);
      }
    }
  } catch (error) {
    // Notification availability must not prevent the app from starting.
    debugPrint('Unable to initialize daily reminder: $error');
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const LanSpeechApp(),
    ),
  );
}

class LanSpeechApp extends ConsumerWidget {
  const LanSpeechApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'LanSpeech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
