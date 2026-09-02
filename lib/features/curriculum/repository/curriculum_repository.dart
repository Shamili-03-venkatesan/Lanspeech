import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lanspeech/features/curriculum/models/chapter.dart';

/// Loads the bundled curriculum content (10 chapters, 120 exercises) from
/// `assets/curriculum/lanspeech_curriculum.json`.
///
/// This is static content authored by the client, not user data, so it
/// ships with the app as a bundled asset rather than living in Supabase.
/// If the client sends a revised curriculum document later, only this JSON
/// asset needs to be regenerated and replaced — no Dart code changes.
class CurriculumRepository {
  static const String _assetPath =
      'assets/curriculum/lanspeech_curriculum.json';

  List<Chapter>? _cache;

  Future<List<Chapter>> loadChapters() async {
    final cached = _cache;
    if (cached != null) return cached;

    final raw = await rootBundle.loadString(_assetPath);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final chaptersJson = decoded['chapters'] as List<dynamic>;

    final chapters = chaptersJson
        .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

    _cache = chapters;
    return chapters;
  }
}

final curriculumRepositoryProvider = Provider<CurriculumRepository>((ref) {
  return CurriculumRepository();
});

/// All 10 chapters with their 12 exercises each, loaded once and cached for
/// the lifetime of the app.
final curriculumProvider = FutureProvider<List<Chapter>>((ref) async {
  final repo = ref.watch(curriculumRepositoryProvider);
  return repo.loadChapters();
});

/// Convenience lookup for a single chapter by number, derived from
/// [curriculumProvider]. Returns null while loading, on error, or if the
/// chapter number doesn't exist.
final chapterByNumberProvider =
    Provider.family<Chapter?, int>((ref, chapterNumber) {
  final chaptersAsync = ref.watch(curriculumProvider);
  return chaptersAsync.maybeWhen(
    data: (chapters) {
      for (final c in chapters) {
        if (c.chapterNumber == chapterNumber) return c;
      }
      return null;
    },
    orElse: () => null,
  );
});
