import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/core/services/preferences_service.dart';
import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/core/services/user_activity_service.dart';
import 'package:lanspeech/features/auth/models/auth_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Real Supabase authentication is enabled. Keep this false unless you are
// intentionally testing a temporary client-only demo flow.
const bool demoLoginEnabled = false;

// ============================================================
// SERVICE PROVIDERS
// ============================================================

final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  return SupabaseService();
});

final userActivityServiceProvider = Provider<UserActivityService>((ref) {
  return UserActivityService();
});

// SharedPreferences is provided from main.dart, but tests and startup
// can also use a fallback.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be overridden in main.dart',
  );
});

final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PreferencesService(prefs);
  } catch (_) {
    return PreferencesService(FakeSharedPreferences());
  }
});

// ============================================================
// FAKE SHARED PREFERENCES
// ============================================================

class FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _values = {};

  @override
  bool? getBool(String key) => _values[key] as bool?;

  @override
  int? getInt(String key) => _values[key] as int?;

  @override
  double? getDouble(String key) => _values[key] as double?;

  @override
  String? getString(String key) => _values[key] as String?;

  @override
  bool containsKey(String key) => _values.containsKey(key);

  @override
  List<String>? getStringList(String key) =>
      (_values[key] as List<String>?)?.toList();

  @override
  Future<bool> setBool(String key, bool value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
  ) async {
    _values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _values.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _values.clear();
    return true;
  }

  @override
  Future<void> reload() async {}

  @override
  Set<String> getKeys() => _values.keys.toSet();

  @override
  Object? get(String key) => _values[key];

  @override
  String? getStringOrNull(String key) => getString(key);

  @override
  bool? getBoolOrNull(String key) => getBool(key);

  @override
  int? getIntOrNull(String key) => getInt(key);

  @override
  double? getDoubleOrNull(String key) => getDouble(key);

  @override
  List<String>? getStringListOrNull(String key) => getStringList(key);

  @override
  Future<bool> commit() async => true;
}

// ============================================================
// AUTHENTICATION STATE NOTIFIER
// ============================================================

class AuthNotifier extends StateNotifier<CustomAuthState> {
  final SupabaseService _supabaseService;
  final PreferencesService _prefsService;
  final UserActivityService _userActivityService;

  AuthNotifier(
    this._supabaseService,
    this._prefsService,
    this._userActivityService,
  ) : super(CustomAuthState.initial()) {
    _initialize();
  }

  // ==========================================================
  // USER ACTIVITY TRACKING
  // ==========================================================

  Future<void> _trackUserActivity() async {
    await _userActivityService.trackActivity();
  }

  // ==========================================================
  // INITIALIZE AND CHECK CURRENT SESSION
  // ==========================================================

  void _initialize() {
    try {
      final user = _supabaseService.currentUser;

      if (user != null) {
        state = CustomAuthState.authenticated(user);

        // Track activity when an existing session is found.
        unawaited(_trackUserActivity());
      } else {
        state = CustomAuthState.unauthenticated();
      }

      // Listen to real-time auth changes.
      _supabaseService.authStateChanges.listen((data) {
        final user = data.session?.user;

        if (user != null) {
          state = CustomAuthState.authenticated(user);

          // Track activity whenever authentication succeeds.
          unawaited(_trackUserActivity());
        } else {
          state = CustomAuthState.unauthenticated();
        }
      });
    } catch (_) {
      state = CustomAuthState.unauthenticated();
    }
  }

  // ==========================================================
  // SIGN IN
  // ==========================================================

  Future<void> login(String email, String password) async {
    state = CustomAuthState.loading();

    // Temporary demo login.
    if (demoLoginEnabled) {
      state = CustomAuthState.demoAuthenticated(email.trim());
      return;
    }

    try {
      final response = await _supabaseService.signInWithEmail(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = CustomAuthState.authenticated(response.user!);

        // Track successful login.
        unawaited(_trackUserActivity());
      } else {
        state = CustomAuthState.unauthenticated();
      }
    } catch (e) {
      state = CustomAuthState.error(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ==========================================================
  // REGISTER
  // ==========================================================

  Future<void> register(
    String name,
    String email,
    String password,
  ) async {
    state = CustomAuthState.loading();

    try {
      final response = await _supabaseService.signUpWithEmail(
        name: name,
        email: email,
        password: password,
      );

      // If email confirmation is required, user is not immediately
      // authenticated.
      if (response.user != null && response.session == null) {
        state = CustomAuthState.verificationSent();
      } else if (response.user != null) {
        state = CustomAuthState.authenticated(response.user!);

        // Track successful registration.
        unawaited(_trackUserActivity());
      } else {
        state = CustomAuthState.unauthenticated();
      }
    } catch (e) {
      state = CustomAuthState.error(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ==========================================================
  // RESET PASSWORD
  // ==========================================================

  Future<void> forgotPassword(String email) async {
    state = CustomAuthState.loading();

    try {
      await _supabaseService.sendPasswordResetEmail(email);

      state = CustomAuthState.verificationSent();
    } catch (e) {
      state = CustomAuthState.error(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  // ==========================================================
  // SIGN OUT
  // ==========================================================

  Future<void> logout() async {
    state = CustomAuthState.loading();

    try {
      await _supabaseService.signOut();

      // Keep completed onboarding state, but clear goals /
      // custom reminders for fresh experience.
      await _prefsService.setSelectedGoals([]);

      state = CustomAuthState.unauthenticated();
    } catch (e) {
      state = CustomAuthState.error(
        e.toString().replaceAll('Exception: ', ''),
      );
    }
  }
}

// ============================================================
// AUTH PROVIDER
// ============================================================

final authProvider =
    StateNotifierProvider<AuthNotifier, CustomAuthState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  final prefs = ref.watch(preferencesServiceProvider);
  final activityService = ref.watch(userActivityServiceProvider);

  return AuthNotifier(
    supabase,
    prefs,
    activityService,
  );
});

// ============================================================
// AUTH STATE CHANGE EFFECT
// ============================================================

/// Effect provider that watches auth state changes and invalidates
/// progress providers to ensure they fetch fresh data for the
/// newly logged-in user.
///
/// This is crucial for cross-device sync: when a user logs in on
/// a new device, the progress providers need to reinitialize and
/// fetch their data from Supabase.
final _authStateChangeEffect = FutureProvider<void>((ref) async {
  final authState = ref.watch(authProvider);

  // When auth state changes (user logs in, logs out, or switches
  // accounts), invalidate the progress providers so they
  // reinitialize with the new user's data.
  if (authState.status == AuthStatus.authenticated ||
      authState.status == AuthStatus.unauthenticated) {
    // Import these providers where needed and add them to this list:
    // ref.invalidate(curriculumProgressProvider);
    // ref.invalidate(gamificationProvider);
    // ref.invalidate(practiceActivityProvider);
  }
});
