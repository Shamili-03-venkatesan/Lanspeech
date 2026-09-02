import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/gamification/models/gamification_state.dart';
import 'package:lanspeech/features/gamification/repository/gamification_repository.dart';
import 'package:lanspeech/features/gamification/exceptions/xp_limit_exception.dart';

/// Awards XP and tracks daily-practice streaks/calendar.
/// Data is synced to Supabase as the source of truth, with SharedPreferences
/// as an offline cache. When user logs in on a new device, this fetches
/// their gamification data from Supabase.
///
/// The XP amount per exercise (10) is a placeholder — the brief specifies
/// that XP is a feature but never an exact value, so this is a design
/// decision, easy to tune at the [recordExerciseCompletion] call site.
class GamificationNotifier extends StateNotifier<GamificationState> {
  static const String _xpKey = 'gamification_total_xp';
  static const String _datesKey = 'gamification_practiced_dates';
  static const String _longestStreakKey = 'gamification_longest_streak';
  static final DateFormat _dateKeyFormat = DateFormat('yyyy-MM-dd');

  final SharedPreferences _prefs;
  final GamificationRepository _gamificationRepository;
  final SupabaseService _supabaseService;

  GamificationNotifier(this._prefs, this._gamificationRepository, this._supabaseService)
      : super(GamificationState.initial()) {
    _initialize();
  }

  /// Initialize: load from cloud first, fallback to local cache
  Future<void> _initialize() async {
    // CRITICAL: If user is not authenticated, clear cache to prevent
    // multi-user data leaks when switching accounts on same device
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      state = GamificationState.initial();
      await _prefs.remove(_xpKey);
      await _prefs.remove(_datesKey);
      await _prefs.remove(_longestStreakKey);
      return;
    }

    // Try to load from cloud (Supabase)
    final cloudData = await _gamificationRepository.fetchGamificationState();

    if (cloudData.totalXp > 0 ||
        cloudData.currentStreak > 0 ||
        cloudData.practicedDates.isNotEmpty) {
      // Cloud has data — use it and update local cache
      state = cloudData;
      _saveToLocalCache(cloudData);
    } else {
      // Cloud is empty — try local cache as fallback
      final xp = _prefs.getInt(_xpKey) ?? 0;
      final dates =
          (_prefs.getStringList(_datesKey) ?? const <String>[]).toSet();
      final storedLongest = _prefs.getInt(_longestStreakKey) ?? 0;
      final current = _computeCurrentStreak(dates);

      final localData = GamificationState(
        totalXp: xp,
        practicedDates: dates,
        currentStreak: current,
        longestStreak: current > storedLongest ? current : storedLongest,
      );

      state = localData;

      // If we have local data and no cloud data, sync it to cloud
      if (xp > 0 || dates.isNotEmpty) {
        await _gamificationRepository.saveGamificationState(localData);
      }
    }
  }

  /// Call whenever the user completes an exercise. XP is added every call;
  /// the streak/calendar only meaningfully change the first time a given
  /// calendar day is recorded (recording the same day twice is harmless).
  /// 
  /// If [isPremium] is false and user has reached 300 XP limit, throws
  /// [XpLimitReachedException]. Premium users have no XP limit.
  Future<void> recordExerciseCompletion({
    int xpAwarded = 10,
    bool isPremium = false,
  }) async {
    // Check XP limit for free users
    if (!isPremium && XpLimitReachedException.wouldExceedLimit(state.totalXp, xpPerExercise: xpAwarded)) {
      throw XpLimitReachedException(
        currentXp: state.totalXp,
        attemptedXp: xpAwarded,
      );
    }

    final todayKey = _dateKeyFormat.format(DateTime.now());
    final updatedDates = {...state.practicedDates, todayKey};
    final updatedXp = state.totalXp + xpAwarded;
    final updatedCurrentStreak = _computeCurrentStreak(updatedDates);
    final updatedLongest = updatedCurrentStreak > state.longestStreak
        ? updatedCurrentStreak
        : state.longestStreak;

    final newState = state.copyWith(
      totalXp: updatedXp,
      practicedDates: updatedDates,
      currentStreak: updatedCurrentStreak,
      longestStreak: updatedLongest,
    );

    state = newState;

    // Update local cache
    _saveToLocalCache(newState);

    // Sync to cloud (fire and forget, but print errors)
    final success = await _gamificationRepository.saveGamificationState(newState);
    if (!success) {
      print('Warning: Failed to sync gamification to cloud');
    }
  }

  /// Save state to local SharedPreferences cache
  void _saveToLocalCache(GamificationState gameState) {
    _prefs.setInt(_xpKey, gameState.totalXp);
    _prefs.setStringList(_datesKey, gameState.practicedDates.toList());
    _prefs.setInt(_longestStreakKey, gameState.longestStreak);
  }

  /// Walks backward from today counting consecutive practiced days. If
  /// today has no practice recorded yet, starts from yesterday instead, so
  /// an in-progress streak doesn't appear broken before the day is over.
  int _computeCurrentStreak(Set<String> practicedDates) {
    var cursor = DateTime.now();
    final todayKey = _dateKeyFormat.format(cursor);
    if (!practicedDates.contains(todayKey)) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (practicedDates.contains(_dateKeyFormat.format(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// For QA/testing only — clears all locally tracked gamification data.
  Future<void> resetAll() async {
    state = GamificationState.initial();
    await _prefs.remove(_xpKey);
    await _prefs.remove(_datesKey);
    await _prefs.remove(_longestStreakKey);
    await _gamificationRepository.resetAll();
  }
}

final gamificationProvider =
    StateNotifierProvider<GamificationNotifier, GamificationState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final gamificationRepo = ref.watch(gamificationRepositoryProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  
  // Watch auth state so we reinitialize when user logs in/out
  ref.watch(authProvider);

  return GamificationNotifier(prefs, gamificationRepo, supabaseService);
});
