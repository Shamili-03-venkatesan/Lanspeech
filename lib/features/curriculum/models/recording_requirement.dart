/// How an exercise's "Recording" (or "Maximum recording" / "Recording
/// duration") note, as written by the client, maps onto whether the
/// microphone should be required, optional, or absent for that exercise.
///
/// This is parsed from the client's own free text (e.g. "Required",
/// "Optional.", "No.", "Yes") rather than a fixed field in the source
/// document, so [unspecified] is a real, expected outcome — 10 of the 120
/// exercises have no explicit Recording-related section at all.
enum RecordingRequirement { none, optional, required, unspecified }

RecordingRequirement recordingRequirementFromNote(String note) {
  final n = note.toLowerCase().trim();
  if (n.contains('not specified')) return RecordingRequirement.unspecified;
  if (n.startsWith('no')) return RecordingRequirement.none;
  if (n.contains('required') || n.startsWith('yes')) {
    return RecordingRequirement.required;
  }
  if (n.contains('optional')) return RecordingRequirement.optional;
  return RecordingRequirement.unspecified;
}

/// Best-effort extraction of a maximum recording duration from free text
/// such as "up to 60 seconds", "Maximum: 90 seconds", or "2 minutes".
/// Returns null when no duration is stated in the text — callers should
/// treat that as "not specified", never as "unlimited".
Duration? maxRecordingDurationFromText(String text) {
  final secondsMatch = RegExp(r'(\d+)\s*second').firstMatch(text);
  if (secondsMatch != null) {
    return Duration(seconds: int.parse(secondsMatch.group(1)!));
  }
  final minutesMatch = RegExp(r'(\d+)\s*minute').firstMatch(text);
  if (minutesMatch != null) {
    return Duration(minutes: int.parse(minutesMatch.group(1)!));
  }
  return null;
}
