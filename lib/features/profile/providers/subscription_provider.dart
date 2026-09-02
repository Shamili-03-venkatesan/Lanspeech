import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/profile/repository/subscription_repository.dart';

// Repository provider for subscription
final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SubscriptionRepository(supabaseService);
});

// Provider for user subscription data
// Refreshes whenever auth state changes
final userSubscriptionProvider = FutureProvider<UserSubscription?>((ref) async {
  // Watch auth state to refresh when user logs in/out
  ref.watch(authProvider);
  
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.fetchSubscription();
});

// Provider for checking if user is Premium
// Useful for conditional UI/logic
final isPremiumProvider = FutureProvider<bool>((ref) async {
  final subscription = await ref.watch(userSubscriptionProvider.future);
  return subscription?.isPremium ?? false;
});
