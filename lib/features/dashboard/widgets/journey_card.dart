// lib/features/dashboard/widgets/journey_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';

class JourneyCard extends StatelessWidget {
  final JourneyProgress journey;

  const JourneyCard({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.teal.withOpacity(0.3) : AppColors.lightGrey,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'YOUR JOURNEY',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
              color: isDark ? AppColors.yellow : AppColors.teal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Day ${journey.currentDay} of ${journey.totalDays}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? AppColors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: journey.progress,
              minHeight: 8,
              backgroundColor:
                  isDark ? AppColors.darkTeal : AppColors.lightGrey,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.teal),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${journey.currentDay} days completed',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark
                  ? AppColors.lightBackground.withOpacity(0.7)
                  : AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
