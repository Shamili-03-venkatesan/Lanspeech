// lib/features/dashboard/widgets/progress_summary_row.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';

class ProgressSummaryRow extends StatelessWidget {
  final ProgressSummary summary;

  const ProgressSummaryRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget stat(String label, String value) {
      return Expanded(
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark
                    ? AppColors.lightBackground.withOpacity(0.7)
                    : AppColors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR PROGRESS',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 11,
            letterSpacing: 1.0,
            color: isDark ? AppColors.yellow : AppColors.teal,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF194148) : AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? AppColors.teal.withOpacity(0.3)
                  : AppColors.lightGrey,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              stat('Practice Time', '${summary.practiceMinutes} min'),
              stat('Sessions', '${summary.sessions}'),
              stat('Fluency', summary.fluencyLabel),
            ],
          ),
        ),
      ],
    );
  }
}
