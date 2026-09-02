import 'package:lanspeech/core/services/supabase_service.dart';

/// Model for subscription/premium status
class UserSubscription {
  final String userId;
  final bool isPremium;
  final String subscriptionTier;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserSubscription({
    required this.userId,
    required this.isPremium,
    required this.subscriptionTier,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserSubscription.initial(String userId) => UserSubscription(
        userId: userId,
        isPremium: false,
        subscriptionTier: 'free',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

  factory UserSubscription.fromJson(Map<String, dynamic> json) =>
      UserSubscription(
        userId: json['user_id'] as String,
        isPremium: json['is_premium'] as bool? ?? false,
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );
}

/// Repository for user subscription/premium status
class SubscriptionRepository {
  final SupabaseService _supabaseService;

  SubscriptionRepository(this._supabaseService);

  /// Fetch the current user's subscription status.
  /// Missing records are treated as the default Free plan.
  Future<UserSubscription?> fetchSubscription() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabaseService.client
          .from('user_subscription')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        return UserSubscription.initial(userId);
      }

      return UserSubscription.fromJson(response);
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }

  /// Check if the current user is Premium
  Future<bool> isPremium() async {
    final subscription = await fetchSubscription();
    return subscription?.isPremium ?? false;
  }

}
