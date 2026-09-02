// lib/features/dashboard/providers/dashboard_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/curriculum/providers/practice_activity_provider.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';

final dashboardProvider = FutureProvider<DashboardData>((ref) async {
  final chapters = await ref.watch(curriculumProvider.future);
  final progress = ref.watch(curriculumProgressProvider);
  final activity = ref.watch(practiceActivityProvider);
  final totalExercises = chapters.fold<int>(
      0, (total, chapter) => total + chapter.exercises.length);
  final completedExercises = progress.completedExerciseIds.length;
  final resumeChapter = chapters.firstWhere(
    (chapter) => chapter.exercises.any(
      (exercise) => !progress.isExerciseComplete(exercise.internalId),
    ),
    orElse: () => chapters.last,
  );
  final resumeExercise = resumeChapter.exercises.firstWhere(
    (exercise) => !progress.isExerciseComplete(exercise.internalId),
    orElse: () => resumeChapter.exercises.last,
  );

  return DashboardData(
    streakDays: activity.streakDays,
    todayExercise: TodayExercise(
      title: resumeExercise.title,
      description: resumeExercise.sections
              .where((section) =>
                  section.label.trim().toLowerCase() == 'what the user sees')
              .firstOrNull
              ?.text ??
          '',
      durationMinutes: resumeExercise.maxRecordingDuration?.inMinutes ?? 0,
      difficulty: resumeExercise.exerciseType,
      chapterNumber: resumeChapter.chapterNumber,
    ),
    dailyGoal: DailyGoal(
      currentMinutes: activity.todayMinutes,
      currentSeconds: activity.todayRecordedSeconds,
      targetMinutes: 14,
    ),
    progressSummary: ProgressSummary(
      practiceMinutes: activity.totalMinutes,
      sessions: activity.sessionCount,
      fluencyLabel: 'Not rated',
    ),
    latestFeedback: const LatestFeedback(
      feedbackText: 'Complete a recording to receive speech feedback.',
    ),
    journey: JourneyProgress(
      currentDay: activity.practiceDates.toSet().length,
      totalDays: totalExercises,
    ),
    currentChapter: ChapterPreview(
      chapterNumber: 0,
      title: '10 Chapters • 120 Exercises',
      completedExercises: completedExercises,
      totalExercises: totalExercises,
    ),
  );
});
