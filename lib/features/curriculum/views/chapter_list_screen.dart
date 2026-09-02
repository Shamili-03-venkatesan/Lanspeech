import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/curriculum/models/chapter.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/features/curriculum/widgets/chapter_list_card.dart';

/// The Practice tab: the full 10-chapter learning path, per the MVP
/// brief's Learning System ("10 Chapters, 120 Exercises... Users complete
/// lessons sequentially") and Gamification ("Chapter unlocking")
/// requirements. Chapter 1 is always unlocked; each subsequent chapter
/// unlocks once the previous one is fully completed.
class ChapterListScreen extends ConsumerWidget {
  const ChapterListScreen({super.key});

  int _firstIncompleteExerciseNumber(
    Chapter chapter,
    CurriculumProgressState progress,
  ) {
    for (final ex in chapter.exercises) {
      if (!progress.isExerciseComplete(ex.internalId)) {
        return ex.exerciseNumber;
      }
    }
    return chapter.exercises.isEmpty ? 1 : chapter.exercises.length;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(curriculumProvider);
    final progress = ref.watch(curriculumProgressProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text(
              "We couldn't load your chapters. Please try again.",
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
          ),
          data: (chapters) {
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Your Practice',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium
                      ?.copyWith(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Text(
                  '10 chapters · 120 exercises',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: isDark
                        ? AppColors.lightBackground.withOpacity(0.7)
                        : AppColors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                for (final chapter in chapters)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Builder(
                      builder: (context) {
                        Chapter? previousChapter;
                        for (final c in chapters) {
                          if (c.chapterNumber == chapter.chapterNumber - 1) {
                            previousChapter = c;
                            break;
                          }
                        }
                        final isLocked = previousChapter != null &&
                            !progress.isChapterComplete(previousChapter);
                        final completedCount =
                            progress.completedCountForChapter(chapter);

                        return ChapterListCard(
                          chapter: chapter,
                          completedCount: completedCount,
                          isLocked: isLocked,
                          onTap: () {
                            final nextExercise = _firstIncompleteExerciseNumber(
                              chapter,
                              progress,
                            );
                            context.push(
                              '/practice/${chapter.chapterNumber}/$nextExercise',
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
