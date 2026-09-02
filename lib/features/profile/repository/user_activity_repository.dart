import 'package:lanspeech/core/services/supabase_service.dart';

/// Repository for tracking user activity (last active timestamp)
/// Used for analytics to determine when users were last active in the app
class UserActivityRepository {
  final SupabaseService _supabaseService;

  UserActivityRepository(this._supabaseService);

  /// Fetch the current user's activity record (if it exists)
  Future<Map<String, dynamic>?> fetchUserActivity() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabaseService.client
          .from('user_activity')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      return response as Map<String, dynamic>?;
    } catch (e) {
      print('Error fetching user activity: $e');
      return null;
    }
  }

  /// Update the user's last_active_at timestamp to now
  /// Creates a record if it doesn't exist (first time user activity)
  Future<bool> updateLastActiveAt() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_activity')
          .upsert(
            {
              'user_id': userId,
              'last_active_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'user_id',
          );
      return true;
    } catch (e) {
      print('Error updating last active timestamp: $e');
      return false;
    }
  }

  /// Get the timestamp of when user was last active
  /// Returns null if no activity record exists
  Future<DateTime?> getLastActiveAt() async {
    final activity = await fetchUserActivity();
    if (activity == null) return null;

    try {
      final timestamp = activity['last_active_at'] as String?;
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
    } catch (e) {
      print('Error parsing last_active_at timestamp: $e');
    }
    return null;
  }

  /// Clear all activity data (testing only)
  Future<bool> resetAll() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return false;

    try {
      await _supabaseService.client
          .from('user_activity')
          .delete()
          .eq('user_id', userId);
      return true;
    } catch (e) {
      print('Error resetting user activity: $e');
      return false;
    }
  }
}
