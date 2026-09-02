import 'package:supabase_flutter/supabase_flutter.dart';

class UserActivityService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Tracks the user's latest activity.
  ///
  /// If the user has no activity record, a new one is created.
  /// If the record already exists, last_active_at is updated.
  Future<void> trackActivity() async {
    final user = _supabase.auth.currentUser;

    // User is not logged in
    if (user == null) {
      return;
    }

    try {
      await _supabase.from('user_activity').upsert(
        {
          'user_id': user.id,
          'last_active_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      // Activity tracking should never crash the app
      print('User activity tracking failed: $e');
    }
  }
}
