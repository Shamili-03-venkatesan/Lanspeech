import 'package:flutter/material.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// The segmented pill-dot progress indicator used at the top of every
/// exercise screen — one rounded segment per exercise in the chapter, the
/// current-and-completed ones filled in amber, the rest a muted teal. This
/// is the chapter/exercise progress element referenced throughout the
/// LanSpeech design system, kept as a single reusable widget so every
/// exercise screen (and any future chapter-list/summary screen) renders it
/// identically.
class ChapterProgressDots extends StatelessWidget {
  final int total;
  final int current; // 1-based

  const ChapterProgressDots({
    super.key,
    required this.total,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: List.generate(total, (index) {
        final segmentNumber = index + 1;
        final isFilled = segmentNumber <= current;
        return Expanded(
          child: Container(
            height: 5,
            margin: EdgeInsets.only(right: index == total - 1 ? 0 : 4),
            decoration: BoxDecoration(
              color: isFilled
                  ? AppColors.yellow
                  : (isDark
                      ? AppColors.teal.withOpacity(0.25)
                      : AppColors.lightGrey),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      }),
    );
  }
}
