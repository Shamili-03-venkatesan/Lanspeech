// lib/features/dashboard/views/practice_placeholder_screen.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';

/// Temporary landing spot for the "Start Practice" CTA until the real
/// speech-recording/AI-analysis module is built.
class PracticePlaceholderScreen extends StatelessWidget {
  const PracticePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.white : AppColors.navy,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.mic_rounded,
                    size: 56,
                    color: isDark ? AppColors.yellow : AppColors.teal),
                const SizedBox(height: 20),
                Text(
                  'Speech practice is on its way',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  "We're building the recording and AI-feedback experience next.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: AppColors.grey),
                ),
                const SizedBox(height: 28),
                CustomButton(
                  text: 'Back to Dashboard',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
