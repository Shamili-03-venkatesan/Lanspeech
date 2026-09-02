import 'exercise.dart';

/// One chapter from the client's LanSpeech curriculum (always 12 exercises
/// in the current content set). Text fields are verbatim from the client's
/// document; fields the client didn't specify come through as the literal
/// string "Not specified by client" rather than being guessed at.
class Chapter {
  final int chapterNumber;
  final String title;
  final String purpose;
  final String estimatedDuration;
  final String difficulty;
  final String? chapterProgression;
  final List<Exercise> exercises;

  const Chapter({
    required this.chapterNumber,
    required this.title,
    required this.purpose,
    required this.estimatedDuration,
    required this.difficulty,
    required this.chapterProgression,
    required this.exercises,
  });

  Exercise? exerciseByNumber(int exerciseNumber) {
    for (final ex in exercises) {
      if (ex.exerciseNumber == exerciseNumber) return ex;
    }
    return null;
  }

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      chapterNumber: json['chapter_number'] as int,
      title: json['title'] as String,
      purpose: json['purpose'] as String,
      estimatedDuration: json['estimated_duration'] as String,
      difficulty: json['difficulty'] as String,
      chapterProgression: json['chapter_progression'] as String?,
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
