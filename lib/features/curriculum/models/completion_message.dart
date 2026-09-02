import 'exercise_section.dart';

/// The message and button label to show once an exercise's coach audio /
/// content has been experienced, parsed from whichever completion-style
/// section the client used for that exercise.
///
/// The client's document uses this content inconsistently across the 120
/// exercises — sometimes a single "Completion screen" section embeds both
/// the message and a trailing "Button: X" label (e.g. CH01_EX01), sometimes
/// the message and button live in two separate sections ("Final message" +
/// "Button", e.g. CH01_EX12), and most exercises only ever give a short
/// encouraging "Completion message" with no button text at all. This
/// normalizes all three shapes without inventing new copy — the fallback
/// message and default "Continue" label are only used in the (currently
/// never-hit) case where an exercise has neither.
class ParsedCompletion {
  final String message;
  final String buttonLabel;

  const ParsedCompletion({required this.message, required this.buttonLabel});

  factory ParsedCompletion.fromSections(List<ExerciseSection> sections) {
    const messageLabels = {
      'completion message',
      'completion screen',
      'final message',
      'final screen',
    };

    String? message;
    String? buttonLabel;

    for (final s in sections) {
      final label = s.label.trim().toLowerCase().replaceAll(':', '');
      if (label == 'button' && buttonLabel == null) {
        buttonLabel = s.text.trim();
      } else if (messageLabels.contains(label) && message == null) {
        message = s.text;
      }
    }

    // A few exercises embed the button label directly in the message text,
    // e.g. "You're ready. Let's begin.  Button:  Continue".
    if (message != null) {
      final embedded =
          RegExp(r'Button:\s*(.+)$', caseSensitive: false).firstMatch(message);
      if (embedded != null) {
        buttonLabel ??= embedded.group(1)!.trim();
        message = message.substring(0, embedded.start).trim();
      }
    }

    return ParsedCompletion(
      message: (message ?? "Nice work. Ready to continue?").trim(),
      buttonLabel: buttonLabel ?? 'Continue',
    );
  }
}
