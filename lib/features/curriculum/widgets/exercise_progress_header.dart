import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/curriculum/widgets/chapter_progress_dots.dart';

/// The header used at the top of every exercise screen: a back chevron
/// (matching the back-button convention already used on the forgot-password
/// screen), a "Chapter N • Exercise M" label, and the segmented progress
/// dots. Kept as one widget so every exercise in every chapter shares
/// exactly the same navigation chrome.
class ExerciseProgressHeader extends StatelessWidget {
  final int chapterNumber;
  final int exerciseNumber;
  final int totalExercises;
  final VoidCallback onBack;

  const ExerciseProgressHeader({
    super.key,
    required this.chapterNumber,
    required this.exerciseNumber,
    required this.totalExercises,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: isDark ? AppColors.white : AppColors.navy,
                  size: 20,
                ),
                onPressed: onBack,
              ),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'Chapter $chapterNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.yellow : AppColors.teal,
                        ),
                      ),
                      TextSpan(
                        text: '  •  Exercise $exerciseNumber',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.white : AppColors.navy,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 40), // balances the back button
            ],
          ),
          const SizedBox(height: 12),
          ChapterProgressDots(total: totalExercises, current: exerciseNumber),
        ],
      ),
    );
  }
}
