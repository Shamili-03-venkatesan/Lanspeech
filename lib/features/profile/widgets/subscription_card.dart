import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/profile/providers/subscription_provider.dart';

/// Shows the user's current plan and an upgrade path, per the MVP brief's
/// "Manage subscription" Profile requirement. Payment integration
/// (RevenueCat / Paystack) is a separate, not-yet-built workstream — this
/// is UI only for now; tapping Upgrade shows a placeholder notice rather
/// than a real purchase flow, the same pattern already used for the
/// Google Sign-In placeholder button on the login screen.
class SubscriptionCard extends ConsumerWidget {
  const SubscriptionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subscriptionAsync = ref.watch(userSubscriptionProvider);

    return subscriptionAsync.when(
      loading: () => _buildCard(
        context: context,
        isDark: isDark,
        isPremium: false,
        isLoading: true,
      ),
      error: (err, _) => _buildCard(
        context: context,
        isDark: isDark,
        isPremium: false,
        isLoading: false,
      ),
      data: (subscription) => _buildCard(
        context: context,
        isDark: isDark,
        isPremium: subscription?.isPremium ?? false,
        isLoading: false,
      ),
    );
  }

  static Widget _buildCard({
    required BuildContext context,
    required bool isDark,
    required bool isPremium,
    required bool isLoading,
  }) {
    final planLabel = isPremium ? 'Premium Plan' : 'Free Plan';
    final planDescription = isPremium
        ? 'Unlimited lessons & XP'
        : 'Limited to 300 XP';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.teal.withOpacity(0.25) : AppColors.lightGrey,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isPremium
                  ? Icons.workspace_premium_rounded
                  : Icons.card_membership_rounded,
              color: AppColors.teal,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  planLabel,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.navy,
                  ),
                ),
                Text(
                  planDescription,
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (!isPremium)
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Premium plans are coming soon.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Upgrade'),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.teal.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Active',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.teal,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
