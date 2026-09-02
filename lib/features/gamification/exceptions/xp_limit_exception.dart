/// Exception thrown when a free user tries to earn XP but has reached the limit
class XpLimitReachedException implements Exception {
  static const int freeUserLimit = 300;
  static const int xpPerExercise = 10;
  
  final int currentXp;
  final int attemptedXp;

  XpLimitReachedException({
    required this.currentXp,
    this.attemptedXp = xpPerExercise,
  });

  @override
  String toString() => 'XP Limit Reached: User has $currentXp/$freeUserLimit XP. '
      'Free users cannot earn more XP. Premium subscription required.';

  /// Returns true if the user can still earn XP
  static bool canEarnXp(int currentXp) {
    return currentXp < freeUserLimit;
  }

  /// Returns true if earning one more exercise worth of XP would exceed the limit
  static bool wouldExceedLimit(int currentXp, {int xpPerExercise = 10}) {
    return currentXp + xpPerExercise > freeUserLimit;
  }
}
