import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/onboarding/providers/onboarding_provider.dart';

class MockDashboardScreen extends ConsumerWidget {
  const MockDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final onboardingState = ref.watch(onboardingProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safe extraction of name from supabase metadata or generic fallback
    final displayName =
        authState.user?.userMetadata?['display_name'] ?? 'Speech Learner';
    final userEmail = authState.user?.email ?? 'learner@lanspeech.com';

    void handleLogout() async {
      await ref.read(authProvider.notifier).logout();
      if (context.mounted) {
        context.go('/login');
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Status Bar (Gamified profile section)
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.teal,
                      child: Text(
                        displayName.isNotEmpty
                            ? displayName[0].toUpperCase()
                            : 'L',
                        style: GoogleFonts.poppins(
                          color: AppColors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello, $displayName!',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 18,
                                ),
                          ),
                          Text(
                            userEmail,
                            style: GoogleFonts.poppins(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Gamified Streaks indicator capsule
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            isDark ? const Color(0xFF194148) : AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        border:
                            Border.all(color: AppColors.teal.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_fire_department_rounded,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 4),
                          Text(
                            '3 Days',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark ? AppColors.white : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Premium Custom Practice Progress Card
                Card(
                  color: AppColors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.star_rounded,
                                  color: AppColors.yellow, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'DAILY TASK COMPLETE!',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.yellow,
                                fontSize: 13,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '"Soft Contact Beginnings"',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Practice introducing phrases with slow, relaxed vocal fold contact.',
                          style: GoogleFonts.poppins(
                            color: AppColors.lightBackground,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Custom Linear Progress
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: const LinearProgressIndicator(
                                  value: 0.7,
                                  backgroundColor: AppColors.darkTeal,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.yellow),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '70%',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.white,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Goals focused checklist
                Text(
                  'Your Selected Goals',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),

                onboardingState.selectedGoals.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF194148)
                              : AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'No goals selected. Jump into onboarding to customize your profile!',
                          style: GoogleFonts.poppins(color: AppColors.grey),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: onboardingState.selectedGoals.map((goal) {
                          return Chip(
                            label: Text(
                              goal,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.teal,
                              ),
                            ),
                            backgroundColor: isDark
                                ? const Color(0xFF194148)
                                : AppColors.lightBackground,
                            side: const BorderSide(
                                color: AppColors.teal, width: 1.2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            avatar: const Icon(Icons.check_circle_rounded,
                                color: AppColors.teal, size: 16),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 24),

                // Daily Schedule Details
                Text(
                  'Speech Schedule',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF194148) : AppColors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.teal.withOpacity(0.3)
                          : AppColors.lightGrey,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.alarm_rounded,
                          color: AppColors.teal, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reminder Active',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color:
                                    isDark ? AppColors.white : AppColors.navy,
                              ),
                            ),
                            Text(
                              'Category: ${onboardingState.reminderLabel} (${onboardingState.reminderTime})',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/onboarding'),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Profile Controls Section
                Card(
                  color: isDark ? const Color(0xFF194148) : AppColors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.lock_reset_rounded,
                              color: AppColors.teal),
                          title: Text(
                            'Change Password',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16),
                          onTap: () {
                            context.push('/forgot-password');
                          },
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.logout_rounded,
                              color: AppColors.error),
                          title: Text(
                            'Sign Out of Session',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.error,
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16, color: AppColors.error),
                          onTap: handleLogout,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
