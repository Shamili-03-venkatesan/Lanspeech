// lib/features/dashboard/models/dashboard_data.dart

class TodayExercise {
  final String title;
  final String description;
  final int durationMinutes;
  final String difficulty; // e.g. 'Beginner'
  final int chapterNumber;

  const TodayExercise({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.difficulty,
    required this.chapterNumber,
  });
}

class DailyGoal {
  final int currentMinutes;
  final int targetMinutes;
  final int currentSeconds;

  const DailyGoal({
    required this.currentMinutes,
    required this.targetMinutes,
    this.currentSeconds = 0,
  });

  bool get isReached => currentSeconds >= targetMinutes * 60;

  double get progress => targetMinutes == 0
      ? 0
      : (currentSeconds / (targetMinutes * 60)).clamp(0, 1);
}

class ProgressSummary {
  final int practiceMinutes;
  final int sessions;
  final String fluencyLabel;

  const ProgressSummary({
    required this.practiceMinutes,
    required this.sessions,
    required this.fluencyLabel,
  });
}

class LatestFeedback {
  final String feedbackText;

  const LatestFeedback({required this.feedbackText});
}

class JourneyProgress {
  final int currentDay;
  final int totalDays;

  const JourneyProgress({required this.currentDay, required this.totalDays});

  double get progress =>
      totalDays == 0 ? 0 : (currentDay / totalDays).clamp(0, 1);
}

class ChapterPreview {
  final int chapterNumber;
  final String title;
  final int completedExercises;
  final int totalExercises;

  const ChapterPreview({
    required this.chapterNumber,
    required this.title,
    required this.completedExercises,
    required this.totalExercises,
  });
}

/// Aggregate model for the whole dashboard screen.
/// This is intentionally flat and serializable-shaped so swapping the mock
/// repository for a real Supabase-backed one later doesn't require UI changes.
class DashboardData {
  final int streakDays;
  final TodayExercise todayExercise;
  final DailyGoal dailyGoal;
  final ProgressSummary progressSummary;
  final LatestFeedback latestFeedback;
  final JourneyProgress journey;
  final ChapterPreview currentChapter;

  const DashboardData({
    required this.streakDays,
    required this.todayExercise,
    required this.dailyGoal,
    required this.progressSummary,
    required this.latestFeedback,
    required this.journey,
    required this.currentChapter,
  });
}
