import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// A simple 7-column grid of the last [daysToShow] days, highlighting the
/// ones with practice recorded — the "Daily practice calendar" required by
/// the MVP brief's Progress Tracking section. Deliberately a plain day
/// grid rather than a full month calendar with navigation, since the brief
/// doesn't specify a particular calendar UI — just that practice days
/// should be visible.
class PracticeCalendar extends StatelessWidget {
  final Set<String> practicedDates; // 'yyyy-MM-dd'
  final int daysToShow;

  const PracticeCalendar({
    super.key,
    required this.practicedDates,
    this.daysToShow = 28,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateKeyFormat = DateFormat('yyyy-MM-dd');
    final dayLabelFormat = DateFormat('d');
    final today = DateTime.now();

    // Oldest day first, so the grid reads chronologically, ending on today.
    final days = List.generate(
      daysToShow,
      (i) => today.subtract(Duration(days: daysToShow - 1 - i)),
    );

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final key = dateKeyFormat.format(day);
        final practiced = practicedDates.contains(key);
        final isToday = key == dateKeyFormat.format(today);

        return Container(
          decoration: BoxDecoration(
            color: practiced
                ? AppColors.teal
                : (isDark ? const Color(0xFF12343B) : AppColors.lightBackground),
            borderRadius: BorderRadius.circular(8),
            border: isToday
                ? Border.all(color: AppColors.yellow, width: 1.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            dayLabelFormat.format(day),
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: practiced
                  ? AppColors.white
                  : (isDark
                      ? AppColors.lightBackground.withOpacity(0.6)
                      : AppColors.grey),
            ),
          ),
        );
      },
    );
  }
}
