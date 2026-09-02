import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/gamification/models/gamification_state.dart';

/// Repository for syncing XP, streaks, and practice calendar to/from Supabase.
/// Acts as the source of truth for gamification data across devices.
class GamificationRepository {
  final SupabaseService _supabaseService;

  GamificationRepository(this._supabaseService);

  /// Fetch gamification data (XP, streaks, practiced dates) for the current user.
  /// Returns initial state if user is not authenticated or no data exists.
  Future<GamificationState> fetchGamificationState() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return GamificationState.initial();

    try {
      final response = await _supabaseService.client
          .from('user_gamification')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // First time user — create initial record
        await _createInitialRecord(userId);
        return GamificationState.initial();
      }

      return GamificationState(
        totalXp: response['total_xp'] as int? ?? 0,
        currentStreak: response['current_streak'] as int? ?? 0,
        longestStreak: response['longest_streak'] as int? ?? 0,
        practicedDates: Set<String>.from(
          (response['practiced_dates'] as List<dynamic>? ?? []).cast<String>(),
        ),
      );
    } catch (e) {
      print('Error fetching gamification state: $e');
      return GamificationState.initial();
    }
  }

  /// Save gamification state to Supabase.
  Future<bool> saveGamificationState(GamificationState state) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_gamification')
          .upsert(
            {
              'user_id': userId,
              'total_xp': state.totalXp,
              'current_streak': state.currentStreak,
              'longest_streak': state.longestStreak,
              'practiced_dates': state.practicedDates.toList(),
              'last_updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          );
      return true;
    } catch (e) {
      print('Error saving gamification state: $e');
      return false;
    }
  }

  /// Add a single practice date to the calendar.
  /// Used when an exercise is completed to update the practice calendar.
  Future<bool> addPracticeDate(String dateKey) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      // Fetch current state
      final response = await _supabaseService.client
          .from('user_gamification')
          .select('practiced_dates')
          .eq('user_id', userId)
          .maybeSingle();

      final currentDates = Set<String>.from(
        (response?['practiced_dates'] as List<dynamic>? ?? []).cast<String>(),
      );
      currentDates.add(dateKey);

      // Update with new date
      await _supabaseService.client
          .from('user_gamification')
          .update({
            'practiced_dates': currentDates.toList(),
            'last_updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId);

      return true;
    } catch (e) {
      print('Error adding practice date: $e');
      return false;
    }
  }

  /// Create initial gamification record for a new user.
  Future<void> _createInitialRecord(String userId) async {
    try {
      await _supabaseService.client.from('user_gamification').insert({
        'user_id': userId,
        'total_xp': 0,
        'current_streak': 0,
        'longest_streak': 0,
        'practiced_dates': [],
        'last_updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating initial gamification record: $e');
    }
  }

  /// Clear all gamification data for current user (testing only).
  Future<bool> resetAll() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_gamification')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error resetting gamification data: $e');
      return false;
    }
  }
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return GamificationRepository(supabase);
});
