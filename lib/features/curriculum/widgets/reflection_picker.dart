import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/features/curriculum/models/exercise_section.dart';
import 'package:lanspeech/features/curriculum/models/reflection_option.dart';

/// Renders one of the client's "Options" / "Reflection" / "Optional
/// reflection" sections as a single-select list. The client's source text
/// isn't split into a formal question + options structure — see
/// [ParsedReflection] for the documented heuristic used to derive one
/// without inventing new content.
class ReflectionPicker extends StatefulWidget {
  final ExerciseSection section;
  final ValueChanged<String>? onSelected;

  const ReflectionPicker({super.key, required this.section, this.onSelected});

  @override
  State<ReflectionPicker> createState() => _ReflectionPickerState();
}

class _ReflectionPickerState extends State<ReflectionPicker> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final parsed = ParsedReflection.fromRawText(widget.section.text);
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
          if (parsed.question != null) ...[
            Text(
              parsed.question!,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: parsed.options.map((option) {
              final isSelected = _selected == option;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = option);
                  widget.onSelected?.call(option);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.teal
                        : (isDark
                            ? const Color(0xFF12343B)
                            : AppColors.lightBackground),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? AppColors.teal : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    option,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.white
                          : (isDark ? AppColors.white : AppColors.navy),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
