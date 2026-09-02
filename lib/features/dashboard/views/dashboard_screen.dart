import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/features/dashboard/providers/dashboard_provider.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';
import 'package:lanspeech/features/curriculum/views/chapter_list_screen.dart';
import 'package:lanspeech/features/profile/views/profile_screen.dart';
import 'package:lanspeech/features/profile/providers/user_activity_provider.dart';
import 'package:lanspeech/features/progress/views/progress_screen.dart';
import 'package:lanspeech/features/dashboard/widgets/ai_feedback_card.dart';
import 'package:lanspeech/features/dashboard/widgets/daily_goal_card.dart';
import 'package:lanspeech/features/dashboard/widgets/greeting_header.dart';
import 'package:lanspeech/features/dashboard/widgets/journey_card.dart';
import 'package:lanspeech/features/dashboard/widgets/main_bottom_nav.dart';
import 'package:lanspeech/features/dashboard/widgets/progress_summary_row.dart';
import 'package:lanspeech/features/dashboard/widgets/streak_badge.dart';
import 'package:lanspeech/features/dashboard/widgets/today_practice_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    // Update user's last active timestamp when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(updateUserActivityProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(onNavTap: (i) => setState(() => _navIndex = i)),
          const ChapterListScreen(),
          const ProgressScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: MainBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  final ValueChanged<int> onNavTap;

  const _HomeTab({required this.onNavTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashboardAsync = ref.watch(dashboardProvider);
    final resumePointAsync = ref.watch(resumePointProvider);
    final curriculumAsync = ref.watch(curriculumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayName =
        authState.user?.userMetadata?['display_name'] as String? ??
            authState.demoEmail ??
            'Speech Learner';

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                "We couldn't load your dashboard. Please try again.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: AppColors.grey),
              ),
            ),
          ),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: GreetingHeader(displayName: displayName)),
                    const SizedBox(width: 12),
                    StreakBadge(days: data.streakDays),
                  ],
                ),
                const SizedBox(height: 24),
                Builder(builder: (context) {
                  final resumePoint = resumePointAsync.valueOrNull;
                  final chapters = curriculumAsync.valueOrNull;
                  TodayExercise todayExercise = data.todayExercise;
                  if (resumePoint != null && chapters != null) {
                    for (final chapter in chapters) {
                      if (chapter.chapterNumber != resumePoint.chapterNumber) {
                        continue;
                      }
                      final exercise =
                          chapter.exerciseByNumber(resumePoint.exerciseNumber);
                      if (exercise != null) {
                        final description = exercise.sections
                            .where((section) =>
                                section.label.trim().toLowerCase() ==
                                'what the user sees')
                            .firstOrNull
                            ?.text;
                        todayExercise = TodayExercise(
                          title: exercise.title,
                          description:
                              description ?? data.todayExercise.description,
                          durationMinutes:
                              exercise.maxRecordingDuration?.inMinutes ??
                                  data.todayExercise.durationMinutes,
                          difficulty: data.todayExercise.difficulty,
                          chapterNumber: chapter.chapterNumber,
                        );
                      }
                      break;
                    }
                  }

                  return TodayPracticeCard(
                    exercise: todayExercise,
                    buttonLabel: resumePointAsync.maybeWhen(
                      data: (rp) => rp.hasStartedAnyPractice
                          ? 'Continue Your Practice'
                          : 'Start Practice',
                      orElse: () => 'Start Practice',
                    ),
                    onStart: () {
                      final resumePoint = resumePointAsync.valueOrNull;
                      final chapterNumber = resumePoint?.chapterNumber ??
                          data.todayExercise.chapterNumber;
                      final exerciseNumber = resumePoint?.exerciseNumber ?? 1;
                      context.push('/practice/$chapterNumber/$exerciseNumber');
                    },
                  );
                }),
                const SizedBox(height: 20),
                DailyGoalCard(goal: data.dailyGoal),
                const SizedBox(height: 20),
                ProgressSummaryRow(summary: data.progressSummary),
                const SizedBox(height: 20),
                AiFeedbackCard(
                  feedback: data.latestFeedback,
                  onViewAnalysis: () => onNavTap(2), // Progress tab
                ),
                const SizedBox(height: 20),
                JourneyCard(journey: data.journey),
                const SizedBox(height: 20),
                _CurriculumOverview(
                  completedExercises: data.currentChapter.completedExercises,
                  totalExercises: data.currentChapter.totalExercises,
                  onContinue: () => onNavTap(1),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurriculumOverview extends StatelessWidget {
  final int completedExercises;
  final int totalExercises;
  final VoidCallback onContinue;

  const _CurriculumOverview({
    required this.completedExercises,
    required this.totalExercises,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.teal.withOpacity(0.3) : AppColors.lightGrey,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR CURRICULUM',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.0,
                color: isDark ? AppColors.yellow : AppColors.teal,
              )),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _overviewStat(context, '10', 'Chapters')),
              Expanded(child: _overviewStat(context, '120', 'Exercises')),
            ],
          ),
          const SizedBox(height: 12),
          Text('$completedExercises / $totalExercises exercises completed',
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey)),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Continue',
            type: ButtonType.secondary,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(children: [
      Text(value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: isDark ? AppColors.white : AppColors.navy,
          )),
      Text(label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: isDark ? AppColors.lightBackground : AppColors.grey,
          )),
    ]);
  }
}
