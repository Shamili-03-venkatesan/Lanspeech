import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/repository/practice_activity_repository.dart';

class PracticeActivity {
  final int totalRecordedSeconds;
  final int sessionCount;
  final List<String> practiceDates;
  final int todayRecordedSeconds;

  const PracticeActivity({
    required this.totalRecordedSeconds,
    required this.sessionCount,
    required this.practiceDates,
    required this.todayRecordedSeconds,
  });

  const PracticeActivity.initial()
      : totalRecordedSeconds = 0,
        sessionCount = 0,
        practiceDates = const [],
        todayRecordedSeconds = 0;

  int get totalMinutes => totalRecordedSeconds ~/ 60;

  int get todayMinutes {
    final today = _dateKey(DateTime.now());
    if (practiceDates.isEmpty || practiceDates.last != today) return 0;
    return todayRecordedSeconds ~/ 60;
  }

  int get streakDays {
    final dates = practiceDates.toSet();
    var day = DateTime.now();
    var streak = 0;
    while (dates.contains(_dateKey(day))) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  PracticeActivity addSession(Duration duration) {
    final today = _dateKey(DateTime.now());
    final previousToday =
        practiceDates.isNotEmpty && practiceDates.last == today
            ? todayRecordedSeconds
            : 0;
    return PracticeActivity(
      totalRecordedSeconds: totalRecordedSeconds + duration.inSeconds,
      sessionCount: sessionCount + 1,
      practiceDates: [...practiceDates, _dateKey(DateTime.now())],
      todayRecordedSeconds: previousToday + duration.inSeconds,
    );
  }

  static String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

class PracticeActivityNotifier extends StateNotifier<PracticeActivity> {
  static const _prefsKey = 'practice_activity';

  final SharedPreferences _prefs;
  final PracticeActivityRepository _practiceActivityRepository;
  final SupabaseService _supabaseService;

  PracticeActivityNotifier(this._prefs, this._practiceActivityRepository, this._supabaseService)
      : super(const PracticeActivity.initial()) {
    _initialize();
  }

  /// Initialize: load from cloud first, fallback to local cache
  Future<void> _initialize() async {
    // CRITICAL: If user is not authenticated, clear cache to prevent
    // multi-user data leaks when switching accounts on same device
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      state = const PracticeActivity.initial();
      await _prefs.remove(_prefsKey);
      return;
    }

    // Try to load from cloud (Supabase)
    final cloudData =
        await _practiceActivityRepository.fetchPracticeActivity();

    if (cloudData.totalRecordedSeconds > 0 ||
        cloudData.sessionCount > 0 ||
        cloudData.practiceDates.isNotEmpty) {
      // Cloud has data — use it and update local cache
      state = cloudData;
      _saveToLocalCache(cloudData);
    } else {
      // Cloud is empty — try local cache as fallback
      final raw = _prefs.getString(_prefsKey);
      if (raw != null) {
        try {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final localData = PracticeActivity(
            totalRecordedSeconds: data['totalRecordedSeconds'] as int? ?? 0,
            sessionCount: data['sessionCount'] as int? ?? 0,
            practiceDates:
                (data['practiceDates'] as List<dynamic>? ?? const [])
                    .cast<String>(),
            todayRecordedSeconds: data['todayRecordedSeconds'] as int? ?? 0,
          );

          state = localData;

          // If we have local data and no cloud data, sync it to cloud
          if (localData.totalRecordedSeconds > 0 ||
              localData.sessionCount > 0) {
            await _practiceActivityRepository.savePracticeActivity(localData);
          }
        } catch (e) {
          print('Error parsing local practice activity: $e');
        }
      }
    }
  }

  /// Record a new practice session: update state, local cache, AND cloud
  Future<void> recordSession(Duration duration) async {
    state = state.addSession(duration);

    // Update local cache
    _saveToLocalCache(state);

    // Sync to cloud (fire and forget, but print errors)
    final success =
        await _practiceActivityRepository.savePracticeActivity(state);
    if (!success) {
      print('Warning: Failed to sync practice activity to cloud');
    }
  }

  /// Save state to local SharedPreferences cache
  void _saveToLocalCache(PracticeActivity activity) {
    _prefs.setString(
      _prefsKey,
      jsonEncode({
        'totalRecordedSeconds': activity.totalRecordedSeconds,
        'sessionCount': activity.sessionCount,
        'practiceDates': activity.practiceDates,
        'todayRecordedSeconds': activity.todayRecordedSeconds,
      }),
    );
  }
}

final practiceActivityProvider =
    StateNotifierProvider<PracticeActivityNotifier, PracticeActivity>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final practiceActivityRepo =
      ref.watch(practiceActivityRepositoryProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  
  // Watch auth state so we reinitialize when user logs in/out
  ref.watch(authProvider);

  return PracticeActivityNotifier(prefs, practiceActivityRepo, supabaseService);
});
