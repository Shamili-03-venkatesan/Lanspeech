import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/profile/repository/user_activity_repository.dart';

// Repository provider for user activity
final userActivityRepositoryProvider = Provider<UserActivityRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return UserActivityRepository(supabaseService);
});

// Provider to update last active timestamp
// Called when user opens/uses the app
final updateUserActivityProvider =
    FutureProvider.autoDispose<bool>((ref) async {
  final repository = ref.watch(userActivityRepositoryProvider);
  return repository.updateLastActiveAt();
});
