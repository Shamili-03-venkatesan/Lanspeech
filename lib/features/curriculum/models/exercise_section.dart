/// The kind of an [ExerciseSection], used by the exercise player to decide
/// whether to render plain text or an interactive control alongside it.
enum ExerciseSectionKind { text, recording, reflection }

ExerciseSectionKind exerciseSectionKindFromString(String raw) {
  switch (raw) {
    case 'recording':
      return ExerciseSectionKind.recording;
    case 'reflection':
      return ExerciseSectionKind.reflection;
    default:
      return ExerciseSectionKind.text;
  }
}

/// One labeled block of content exactly as authored by the client (e.g.
/// "Coach voice", "Options", "Button", "Round 1"). LanSpeech's source
/// curriculum document uses roughly 30 different section labels across its
/// 120 exercises and does not force them into a rigid schema — this type
/// preserves every label and its text, in original order, per exercise, so
/// nothing from the client's document is lost or invented.
class ExerciseSection {
  final String label;
  final String text;
  final ExerciseSectionKind kind;

  const ExerciseSection({
    required this.label,
    required this.text,
    required this.kind,
  });

  factory ExerciseSection.fromJson(Map<String, dynamic> json) {
    return ExerciseSection(
      label: json['label'] as String,
      text: json['text'] as String,
      kind: exerciseSectionKindFromString(json['kind'] as String? ?? 'text'),
    );
  }
}
