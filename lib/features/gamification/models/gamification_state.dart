/// XP, streak, and daily-practice tracking, per the MVP brief's Progress
/// Tracking requirement ("Completed lessons, XP, Streak, Daily practice
/// calendar, Overall progress") and Gamification requirement ("XP, Daily
/// streaks, Chapter unlocking, Achievement badges").
///
/// Streak semantics: the brief doesn't define exact reset/grace rules, so
/// this uses the standard interpretation implied by the brief's own
/// Duolingo comparison — a real daily-practice streak, not a completion
/// counter: it increments the first time a day has a completed exercise,
/// and resets to 1 (not 0) the next time the user practices after a missed
/// day. This is a design decision, not client-specified, and is easy to
/// change in one place ([GamificationNotifier._recomputeStreak]) if the
/// client clarifies otherwise.
class GamificationState {
  final int totalXp;
  final int currentStreak;
  final int longestStreak;

  /// Calendar dates (as 'yyyy-MM-dd' strings, local time) on which at
  /// least one exercise was completed — backs the daily practice calendar.
  final Set<String> practicedDates;

  const GamificationState({
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.practicedDates,
  });

  factory GamificationState.initial() => const GamificationState(
        totalXp: 0,
        currentStreak: 0,
        longestStreak: 0,
        practicedDates: {},
      );

  GamificationState copyWith({
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    Set<String>? practicedDates,
  }) {
    return GamificationState(
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      practicedDates: practicedDates ?? this.practicedDates,
    );
  }
}
