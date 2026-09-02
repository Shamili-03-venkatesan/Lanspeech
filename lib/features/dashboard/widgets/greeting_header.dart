// lib/features/dashboard/widgets/greeting_header.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lanspeech/core/constants/colors.dart';

class GreetingHeader extends StatelessWidget {
  final String displayName;

  const GreetingHeader({super.key, required this.displayName});

  String _greetingForNow() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final firstName = displayName.split(' ').first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_greetingForNow()}, $firstName 👋',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        const SizedBox(height: 4),
        Text(
          "Ready for today's practice?",
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark
                ? AppColors.lightBackground.withOpacity(0.7)
                : AppColors.grey,
          ),
        ),
      ],
    );
  }
}
