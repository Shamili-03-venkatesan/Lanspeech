import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// A single labeled stat (value + label + optional icon) — the shared
/// building block for XP/streak/completed-exercise displays across the
/// Progress and Profile screens.
class StatBlock extends StatelessWidget {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;

  const StatBlock({
    super.key,
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        if (icon != null) ...[
          Icon(icon, color: iconColor ?? AppColors.teal, size: 22),
          const SizedBox(height: 4),
        ],
        Text(
          value,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: isDark ? AppColors.white : AppColors.navy,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: isDark
                ? AppColors.lightBackground.withOpacity(0.7)
                : AppColors.grey,
          ),
        ),
      ],
    );
  }
}

/// A rounded, bordered card containing an evenly-spaced row of
/// [StatBlock]s — mirrors the visual language already used by the
/// dashboard's progress summary card.
class StatRow extends StatelessWidget {
  final List<StatBlock> stats;

  const StatRow({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.teal.withOpacity(0.3) : AppColors.lightGrey,
          width: 1.5,
        ),
      ),
      child: Row(
        children: stats.map((s) => Expanded(child: s)).toList(),
      ),
    );
  }
}
