import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/features/gamification/providers/gamification_provider.dart';
import 'package:lanspeech/features/gamification/widgets/practice_calendar.dart';
import 'package:lanspeech/features/gamification/widgets/stat_block.dart';

/// The Progress tab, per the MVP brief's Progress Tracking requirement:
/// completed lessons, XP, streak, daily practice calendar, overall
/// progress.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gamification = ref.watch(gamificationProvider);
    final progress = ref.watch(curriculumProgressProvider);
    final chaptersAsync = ref.watch(curriculumProvider);

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              "We couldn't load your progress. Please try again.",
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
          ),
          data: (chapters) {
            final totalExercises =
                chapters.fold<int>(0, (sum, c) => sum + c.exercises.length);
            final completedExercises = progress.completedExerciseIds.length;
            final overallProgress =
                totalExercises == 0 ? 0.0 : completedExercises / totalExercises;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Your Progress',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 20),
                StatRow(
                  stats: [
                    StatBlock(
                      value: '${gamification.totalXp}',
                      label: 'XP',
                      icon: Icons.bolt_rounded,
                      iconColor: AppColors.yellow,
                    ),
                    StatBlock(
                      value: '${gamification.currentStreak}',
                      label: 'Day Streak',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: Colors.orange,
                    ),
                    StatBlock(
                      value: '$completedExercises',
                      label: 'Completed',
                      icon: Icons.check_circle_rounded,
                      iconColor: AppColors.teal,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Overall Progress',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF194148) : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.teal.withOpacity(0.25)
                          : AppColors.lightGrey,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 10,
                          backgroundColor:
                              isDark ? AppColors.darkTeal : AppColors.lightGrey,
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(AppColors.teal),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$completedExercises of $totalExercises exercises completed',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.lightBackground.withOpacity(0.7)
                              : AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Practice Calendar',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Last 28 days',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.lightBackground.withOpacity(0.6)
                        : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF194148) : AppColors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark
                          ? AppColors.teal.withOpacity(0.25)
                          : AppColors.lightGrey,
                      width: 1.5,
                    ),
                  ),
                  child: PracticeCalendar(
                    practicedDates: gamification.practicedDates,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          },
        ),
      ),
    );
  }
}
