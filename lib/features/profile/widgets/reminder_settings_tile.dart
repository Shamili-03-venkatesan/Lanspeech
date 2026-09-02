import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/onboarding/providers/onboarding_provider.dart';

/// Lets the user change their daily reminder time, per the MVP brief's
/// "Change reminder settings" Profile requirement — reusing the SAME
/// [onboardingProvider] state/persistence already set up during
/// onboarding, not a separate parallel system. The UI here is fresh
/// (compact, single tile) rather than reusing onboarding's own reminder
/// page directly, since that page is private to the onboarding screen and
/// onboarding itself isn't touched by this feature.
class ReminderSettingsTile extends ConsumerWidget {
  const ReminderSettingsTile({super.key});

  String _formatTime(String time24h) {
    try {
      final parsed = DateFormat('HH:mm').parse(time24h);
      return DateFormat('h:mm a').format(parsed);
    } catch (_) {
      return time24h;
    }
  }

  Future<void> _openTimePicker(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
  ) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = currentTime.split(':');
      initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {}

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
        await ref
          .read(onboardingProvider.notifier)
          .setCustomReminderTime('$hour:$minute');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = ref.watch(onboardingProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.teal.withOpacity(0.25) : AppColors.lightGrey,
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm_rounded, color: AppColors.teal, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Reminder',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isDark ? AppColors.white : AppColors.navy,
                  ),
                ),
                Text(
                  '${state.reminderLabel} · ${_formatTime(state.reminderTime)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppColors.grey),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _openTimePicker(context, ref, state.reminderTime),
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }
}
