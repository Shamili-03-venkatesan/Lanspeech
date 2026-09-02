class OnboardingState {
  final List<String> selectedGoals;
  final String reminderLabel; // Morning, Afternoon, Evening, Custom
  final String reminderTime; // e.g. "09:00"
  final bool isCompleted;

  OnboardingState({
    required this.selectedGoals,
    required this.reminderLabel,
    required this.reminderTime,
    required this.isCompleted,
  });

  factory OnboardingState.initial() {
    return OnboardingState(
      selectedGoals: [],
      reminderLabel: 'Morning',
      reminderTime: '08:00',
      isCompleted: false,
    );
  }

  OnboardingState copyWith({
    List<String>? selectedGoals,
    String? reminderLabel,
    String? reminderTime,
    bool? isCompleted,
  }) {
    return OnboardingState(
      selectedGoals: selectedGoals ?? this.selectedGoals,
      reminderLabel: reminderLabel ?? this.reminderLabel,
      reminderTime: reminderTime ?? this.reminderTime,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
