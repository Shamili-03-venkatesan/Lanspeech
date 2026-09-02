import 'activity_type.dart';
import 'exercise_section.dart';
import 'recording_requirement.dart';

/// One exercise from the client's LanSpeech curriculum document.
///
/// [title], [exerciseType], and [sections] are verbatim from the client's
/// doc. [broadActivityTypes] and [recordingRequirement]/[maxRecordingDuration]
/// are lightly derived from that same text, not invented independently.
///
/// [internalId] (e.g. "CH01_EX07") is for developers and the database only
/// and must never be shown in the UI — this is an explicit rule from the
/// client's document ("Important Mobile Design Rule").
class Exercise {
  final String internalId;
  final int exerciseNumber;
  final String title;
  final String exerciseType;
  final List<ActivityType> broadActivityTypes;
  final String recordingNote;
  final List<ExerciseSection> sections;

  const Exercise({
    required this.internalId,
    required this.exerciseNumber,
    required this.title,
    required this.exerciseType,
    required this.broadActivityTypes,
    required this.recordingNote,
    required this.sections,
  });

  RecordingRequirement get recordingRequirement =>
      recordingRequirementFromNote(recordingNote);

  /// Looks for a stated duration first among sections explicitly tagged as
  /// recording-related, then falls back to the exercise's overall
  /// [recordingNote]. Returns null when the client never stated one.
  Duration? get maxRecordingDuration {
    for (final section in sections) {
      if (section.kind == ExerciseSectionKind.recording) {
        final d = maxRecordingDurationFromText(section.text);
        if (d != null) return d;
      }
    }
    return maxRecordingDurationFromText(recordingNote);
  }

  List<ExerciseSection> get reflectionSections => sections
      .where((s) => s.kind == ExerciseSectionKind.reflection)
      .toList();

  bool get hasReflection => reflectionSections.isNotEmpty;

  bool get involvesRecording =>
      broadActivityTypes.contains(ActivityType.record) ||
      recordingRequirement == RecordingRequirement.required ||
      recordingRequirement == RecordingRequirement.optional;

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      internalId: json['internal_id'] as String,
      exerciseNumber: json['exercise_number'] as int,
      title: json['title'] as String,
      exerciseType: json['exercise_type'] as String,
      broadActivityTypes: activityTypesFromJsonList(
        json['broad_activity_types'] as List<dynamic>,
      ),
      recordingNote: json['recording_note'] as String,
      sections: (json['sections'] as List<dynamic>)
          .map((s) => ExerciseSection.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}
