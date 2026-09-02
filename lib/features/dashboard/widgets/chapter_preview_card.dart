// lib/features/dashboard/widgets/chapter_preview_card.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';

class ChapterPreviewCard extends StatelessWidget {
  final ChapterPreview chapter;
  final VoidCallback onContinue;

  const ChapterPreviewCard({
    super.key,
    required this.chapter,
    required this.onContinue,
  });

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
            'CHAPTER ${chapter.chapterNumber}',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 1.0,
              color: isDark ? AppColors.yellow : AppColors.teal,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            chapter.title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? AppColors.white : AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${chapter.completedExercises} / ${chapter.totalExercises} exercises completed',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark
                  ? AppColors.lightBackground.withOpacity(0.7)
                  : AppColors.grey,
            ),
          ),
          const SizedBox(height: 14),
          CustomButton(
            text: 'Continue',
            type: ButtonType.secondary,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}
