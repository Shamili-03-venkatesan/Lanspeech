/// The result of sending a user's recording to the backend for analysis:
/// a transcript (speech-to-text) and a short, encouraging, non-clinical
/// coach-style feedback message generated from it.
class SpeechAnalysisResult {
  final String transcript;
  final String feedback;
  final int speakingDurationSeconds;
  final double speakingPaceWpm;
  final int pauseCount;
  final int hesitationCount;
  final String fluency;

  const SpeechAnalysisResult({
    required this.transcript,
    required this.feedback,
    required this.speakingDurationSeconds,
    required this.speakingPaceWpm,
    required this.pauseCount,
    required this.hesitationCount,
    required this.fluency,
  });
}
