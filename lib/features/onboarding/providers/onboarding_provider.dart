import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lanspeech/core/services/notification_service.dart';
import 'package:lanspeech/core/services/preferences_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/onboarding/models/onboarding_state.dart';

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PreferencesService _prefsService;
  final NotificationService _notificationService;

  OnboardingNotifier(this._prefsService, this._notificationService)
      : super(OnboardingState.initial()) {
    _loadFromPreferences();
  }

  // Load saved state
  void _loadFromPreferences() {
    final completed = _prefsService.isOnboardingCompleted();
    final goals = _prefsService.getSelectedGoals();
    final label = _prefsService.getReminderLabel();
    final time = _prefsService.getReminderTime() ?? _getDefaultTime(label);

    state = OnboardingState(
      selectedGoals: goals,
      reminderLabel: label,
      reminderTime: time,
      isCompleted: completed,
    );
  }

  String _getDefaultTime(String label) {
    switch (label) {
      case 'Morning':
        return '08:00';
      case 'Afternoon':
        return '13:00';
      case 'Evening':
        return '19:00';
      default:
        return '09:00';
    }
  }

  // Toggle Goal selection
  void toggleGoal(String goal) {
    final currentGoals = List<String>.from(state.selectedGoals);
    if (currentGoals.contains(goal)) {
      currentGoals.remove(goal);
    } else {
      currentGoals.add(goal);
    }
    state = state.copyWith(selectedGoals: currentGoals);
    _prefsService.setSelectedGoals(currentGoals);
  }

  // Update Reminder Label
  Future<void> setReminderLabel(String label) async {
    String time = state.reminderTime;
    if (label != 'Custom') {
      time = _getDefaultTime(label);
    }
    state = state.copyWith(reminderLabel: label, reminderTime: time);
    await _prefsService.setReminderLabel(label);
    await _prefsService.setReminderTime(time);
    if (state.isCompleted) {
      await _notificationService.scheduleDailyReminder(time);
    }
  }

  // Update Custom Reminder Time
  Future<void> setCustomReminderTime(String time24h) async {
    state = state.copyWith(reminderLabel: 'Custom', reminderTime: time24h);
    await _prefsService.setReminderLabel('Custom');
    await _prefsService.setReminderTime(time24h);
    if (state.isCompleted) {
      await _notificationService.scheduleDailyReminder(time24h);
    }
  }

  // Complete onboarding
  Future<void> completeOnboarding() async {
    state = state.copyWith(isCompleted: true);
    await _prefsService.setOnboardingCompleted(true);
    final reminderTime = _prefsService.getReminderTime();
    if (reminderTime == null) {
      await _notificationService.cancelDailyReminder();
      return;
    }
    await _notificationService.scheduleDailyReminder(reminderTime);
  }

  // Reset local state (mainly for testing or logging out)
  Future<void> reset() async {
    await _notificationService.cancelDailyReminder();
    await _prefsService.clearAll();
    state = OnboardingState.initial();
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final prefsService = ref.watch(preferencesServiceProvider);
  final notificationService = NotificationService();
  return OnboardingNotifier(prefsService, notificationService);
});
