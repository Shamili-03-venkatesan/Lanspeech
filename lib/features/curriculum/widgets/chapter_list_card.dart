import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/curriculum/models/chapter.dart';

/// One row in the chapter list (Practice tab): chapter number/title,
/// completion progress, and a locked state for chapters not yet reached —
/// implements the MVP brief's "Users complete lessons sequentially" and
/// "Chapter unlocking" gamification requirement.
class ChapterListCard extends StatelessWidget {
  final Chapter chapter;
  final int completedCount;
  final bool isLocked;
  final VoidCallback? onTap;

  const ChapterListCard({
    super.key,
    required this.chapter,
    required this.completedCount,
    required this.isLocked,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = chapter.exercises.length;
    final isComplete = !isLocked && total > 0 && completedCount >= total;

    return Opacity(
      opacity: isLocked ? 0.5 : 1.0,
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF194148) : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isComplete
                  ? AppColors.teal
                  : (isDark
                      ? AppColors.teal.withOpacity(0.25)
                      : AppColors.lightGrey),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isComplete ? AppColors.teal : AppColors.teal.withOpacity(0.12),
                ),
                child: Icon(
                  isLocked
                      ? Icons.lock_rounded
                      : (isComplete
                          ? Icons.check_rounded
                          : Icons.menu_book_rounded),
                  color: isComplete ? AppColors.white : AppColors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHAPTER ${chapter.chapterNumber}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.yellow : AppColors.teal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      chapter.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.white : AppColors.navy,
                      ),
                    ),
                    if (!isLocked) ...[
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: total == 0 ? 0 : completedCount / total,
                          minHeight: 6,
                          backgroundColor:
                              isDark ? AppColors.darkTeal : AppColors.lightGrey,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.yellow),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount / $total exercises',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.lightBackground.withOpacity(0.7)
                              : AppColors.grey,
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 4),
                      Text(
                        'Complete Chapter ${chapter.chapterNumber - 1} to unlock',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.lightBackground.withOpacity(0.6)
                              : AppColors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!isLocked)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark
                      ? AppColors.white.withOpacity(0.6)
                      : AppColors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
