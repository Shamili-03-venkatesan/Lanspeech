import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';
import 'package:lanspeech/features/dashboard/models/dashboard_data.dart';

class TodayPracticeCard extends StatelessWidget {
  final TodayExercise exercise;
  final VoidCallback onStart;

  /// Defaults to 'Start Practice' — unchanged from before. The dashboard
  /// now passes 'Continue Your Practice' once the user has any completed
  /// exercise, via resumePointProvider.hasStartedAnyPractice.
  final String buttonLabel;

  const TodayPracticeCard({
    super.key,
    required this.exercise,
    required this.onStart,
    this.buttonLabel = 'Start Practice',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.teal,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded,
                      color: AppColors.yellow, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  "TODAY'S PRACTICE",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: AppColors.yellow,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              exercise.title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              exercise.description,
              style: GoogleFonts.poppins(
                color: AppColors.lightBackground,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '${exercise.durationMinutes} min • ${exercise.difficulty} • Chapter ${exercise.chapterNumber}',
              style: GoogleFonts.poppins(
                color: AppColors.lightBackground.withOpacity(0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: buttonLabel,
              onPressed: onStart,
              width: double.infinity,
            ),
          ],
        ),
      ),
    );
  }
}
