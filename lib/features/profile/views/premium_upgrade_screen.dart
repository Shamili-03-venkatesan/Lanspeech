import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';

/// Screen shown when a free user reaches the 300 XP limit and wants to continue practicing
class PremiumUpgradeScreen extends StatelessWidget {
  const PremiumUpgradeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        title: const Text('Unlock Premium'),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon / Badge
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: AppColors.teal,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Heading
              Center(
                child: Text(
                  'You\'ve Reached Your Free Limit',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.navy,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Subheading
              Center(
                child: Text(
                  'Free users can earn up to 300 XP.\nUpgrade to Premium to keep practicing!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Benefits List
              Text(
                'Premium Benefits',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
              const SizedBox(height: 16),

              _BenefitTile(
                icon: Icons.star,
                title: 'Unlimited XP',
                description: 'No 300 XP cap. Keep earning without limits.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.analytics,
                title: 'Advanced Analytics',
                description: 'Track your progress across all devices.',
                isDark: isDark,
              ),
              const SizedBox(height: 12),

              _BenefitTile(
                icon: Icons.headset_mic,
                title: 'Priority Support',
                description: 'Get faster responses to your questions.',
                isDark: isDark,
              ),
              const SizedBox(height: 40),

              // Pricing Info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.teal.withOpacity(0.25),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LanSpeech Premium',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.white : AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pricing details coming soon.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Upgrade Button
              CustomButton(
                text: 'Upgrade to Premium',
                onPressed: () {
                  // TODO: Connect to payment provider (Stripe/Paystack)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment integration coming soon.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Back to Dashboard',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: AppColors.teal,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Individual benefit tile
class _BenefitTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool isDark;

  const _BenefitTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppColors.teal,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.white : AppColors.navy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: AppColors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
