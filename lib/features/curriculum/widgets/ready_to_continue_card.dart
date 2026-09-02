import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// The bottom "message + Continue" card shown once an exercise is ready to
/// move on. The message and button label come from whichever completion
/// -style section the client wrote for that exercise (see
/// [ParsedCompletion]) — never invented copy, just the client's own
/// encouraging line for that specific exercise.
///
/// This is the single reusable "ready to continue" component for every
/// exercise in every chapter, so the moment always feels the same across
/// the whole app even though the message text changes per exercise.
class ReadyToContinueCard extends StatelessWidget {
  final String message;
  final String buttonLabel;
  final VoidCallback onContinue;

  const ReadyToContinueCard({
    super.key,
    required this.message,
    required this.buttonLabel,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal,
            ),
            child: const Icon(
              Icons.chat_bubble_rounded,
              color: AppColors.yellow,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.35,
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: onContinue,
            // Deliberately no explicit ElevatedButtonThemeData override
            // here — this relies on the app's existing global
            // elevatedButtonTheme (teal background, white text, rounded
            // corners) defined in AppTheme, just with tighter padding so
            // it reads as a compact pill inside this row rather than the
            // full-width primary button style.
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(buttonLabel),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios_rounded, size: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
