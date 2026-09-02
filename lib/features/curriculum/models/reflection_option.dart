/// A reflection/options section parsed into an optional heading question
/// and a list of selectable option lines, derived from the client's raw
/// text (e.g. an "Options" or "Reflection" section).
///
/// The client's source document does not separate "question" from
/// "options" as distinct fields — it's free text with line breaks
/// (collapsed to double-spaces when the curriculum JSON was generated).
/// This applies a light, documented heuristic instead of inventing new
/// content: a line ending in "?" is treated as the heading; every other
/// line becomes a selectable option. Sections that don't fit this pattern
/// still render correctly — every line just becomes an option with no
/// heading shown.
class ParsedReflection {
  final String? question;
  final List<String> options;

  const ParsedReflection({required this.question, required this.options});

  factory ParsedReflection.fromRawText(String raw) {
    final lines = raw
        .split('  ')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    String? question;
    final options = <String>[];
    for (final line in lines) {
      final looksLikeHeading = question == null &&
          (line.endsWith('?') ||
              line.toLowerCase().startsWith('the user sees'));
      if (looksLikeHeading) {
        question = line;
      } else {
        options.add(line);
      }
    }
    return ParsedReflection(question: question, options: options);
  }
}
