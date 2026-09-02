// lib/features/dashboard/widgets/ai_feedback_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';

class AiFeedbackCard extends StatelessWidget {
  final LatestFeedback feedback;
  final VoidCallback onViewAnalysis;

  const AiFeedbackCard({
    super.key,
    required this.feedback,
    required this.onViewAnalysis,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.teal, size: 18),
              const SizedBox(width: 8),
              Text(
                'YOUR LATEST FEEDBACK',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 1.0,
                  color: isDark ? AppColors.yellow : AppColors.teal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${feedback.feedbackText}"',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.4,
              color: isDark ? AppColors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: onViewAnalysis,
            child: Text(
              'View Analysis →',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? AppColors.yellow : AppColors.teal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
