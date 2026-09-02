import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/providers/practice_activity_provider.dart';

/// Repository for syncing practice activity (recording time, session count) to/from Supabase.
/// Acts as the source of truth for practice activity data across devices.
class PracticeActivityRepository {
  final SupabaseService _supabaseService;

  PracticeActivityRepository(this._supabaseService);

  /// Fetch practice activity data for the current user.
  /// Returns initial state if user is not authenticated or no data exists.
  Future<PracticeActivity> fetchPracticeActivity() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return const PracticeActivity.initial();

    try {
      final response = await _supabaseService.client
          .from('user_practice_activity')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // First time user — create initial record
        await _createInitialRecord(userId);
        return const PracticeActivity.initial();
      }

      return PracticeActivity(
        totalRecordedSeconds: response['total_recorded_seconds'] as int? ?? 0,
        sessionCount: response['session_count'] as int? ?? 0,
        practiceDates: List<String>.from(
          (response['practice_dates'] as List<dynamic>? ?? []).cast<String>(),
        ),
        todayRecordedSeconds: response['today_recorded_seconds'] as int? ?? 0,
      );
    } catch (e) {
      print('Error fetching practice activity: $e');
      return const PracticeActivity.initial();
    }
  }

  /// Save practice activity to Supabase.
  Future<bool> savePracticeActivity(PracticeActivity activity) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_practice_activity')
          .upsert(
            {
              'user_id': userId,
              'total_recorded_seconds': activity.totalRecordedSeconds,
              'session_count': activity.sessionCount,
              'practice_dates': activity.practiceDates,
              'today_recorded_seconds': activity.todayRecordedSeconds,
              'last_updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          );
      return true;
    } catch (e) {
      print('Error saving practice activity: $e');
      return false;
    }
  }

  /// Create initial practice activity record for a new user.
  Future<void> _createInitialRecord(String userId) async {
    try {
      await _supabaseService.client.from('user_practice_activity').insert({
        'user_id': userId,
        'total_recorded_seconds': 0,
        'session_count': 0,
        'practice_dates': [],
        'today_recorded_seconds': 0,
        'last_updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating initial practice activity record: $e');
    }
  }

  /// Clear all practice activity for current user (testing only).
  Future<bool> resetAll() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_practice_activity')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error resetting practice activity: $e');
      return false;
    }
  }
}

final practiceActivityRepositoryProvider =
    Provider<PracticeActivityRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return PracticeActivityRepository(supabase);
});
