import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keyOnboardingCompleted = 'onboarding_completed';
  static const String _keyReminderTime = 'daily_reminder_time';
  static const String _keyReminderLabel =
      'daily_reminder_label'; // Morning, Afternoon, Evening, Custom
  static const String _keySelectedGoals = 'selected_goals';

  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  // Onboarding Completion
  bool isOnboardingCompleted() {
    return _prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _prefs.setBool(_keyOnboardingCompleted, completed);
  }

  // Daily Reminders
  String? getReminderTime() {
    return _prefs.getString(_keyReminderTime);
  }

  Future<void> setReminderTime(String time24h) async {
    await _prefs.setString(_keyReminderTime, time24h);
  }

  String getReminderLabel() {
    return _prefs.getString(_keyReminderLabel) ?? 'Morning';
  }

  Future<void> setReminderLabel(String label) async {
    await _prefs.setString(_keyReminderLabel, label);
  }

  // Selected Speech Goals
  List<String> getSelectedGoals() {
    return _prefs.getStringList(_keySelectedGoals) ?? [];
  }

  Future<void> setSelectedGoals(List<String> goals) async {
    await _prefs.setStringList(_keySelectedGoals, goals);
  }

  // Clear all for testing / logouts
  Future<void> clearAll() async {
    await _prefs.remove(_keyOnboardingCompleted);
    await _prefs.remove(_keyReminderTime);
    await _prefs.remove(_keyReminderLabel);
    await _prefs.remove(_keySelectedGoals);
  }
}
