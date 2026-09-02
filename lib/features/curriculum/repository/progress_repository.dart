import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';

/// Repository for syncing completed exercise progress to/from Supabase.
/// Acts as the source of truth for exercise completion state across devices.
class ProgressRepository {
  final SupabaseService _supabaseService;

  ProgressRepository(this._supabaseService);

  /// Fetch all exercise IDs that have been completed by the current user.
  /// Returns empty set if user is not authenticated.
  Future<Set<String>> fetchCompletedExercises() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return {};

    try {
      final response = await _supabaseService.client
          .from('user_exercise_progress')
          .select('exercise_id')
          .eq('user_id', userId);

      if (response is List) {
        return (response as List<dynamic>)
            .map((row) => row['exercise_id'] as String)
            .toSet();
      }
      return {};
    } catch (e) {
      print('Error fetching completed exercises: $e');
      return {};
    }
  }

  /// Mark a single exercise as completed for the current user.
  /// Creates a record in Supabase with the completion timestamp.
  Future<bool> markExerciseComplete(String exerciseId) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_exercise_progress')
          .upsert(
            {
              'user_id': userId,
              'exercise_id': exerciseId,
              'completed_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id,exercise_id',
          );
      return true;
    } catch (e) {
      print('Error marking exercise complete: $e');
      return false;
    }
  }

  /// Batch sync multiple completed exercises at once.
  /// Useful for syncing local cache to cloud after offline period.
  Future<bool> syncCompletedExercises(Set<String> exerciseIds) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null || exerciseIds.isEmpty) return userId != null;

    try {
      final records = exerciseIds
          .map((id) => {
                'user_id': userId,
                'exercise_id': id,
                'completed_at': DateTime.now().toIso8601String(),
              })
          .toList();

      await _supabaseService.client
          .from('user_exercise_progress')
          .upsert(
            records,
            onConflict: 'user_id,exercise_id',
          );
      return true;
    } catch (e) {
      print('Error syncing completed exercises: $e');
      return false;
    }
  }

  /// Clear all exercise progress for current user (testing only).
  Future<bool> resetAll() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_exercise_progress')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error resetting exercise progress: $e');
      return false;
    }
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ProgressRepository(supabase);
});
