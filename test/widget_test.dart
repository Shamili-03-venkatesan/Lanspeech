import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lanspeech/core/routes/app_router.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/main.dart' as app_entry;

void main() {
  test('main entrypoint is available', () {
    expect(app_entry.main, isA<Function>());
  });

  test('Chapter 1 keeps every Coach voice section', () async {
    final chapters = await CurriculumRepository().loadChapters();
    final chapterOne =
        chapters.singleWhere((chapter) => chapter.chapterNumber == 1);
    final coachVoiceSections = chapterOne.exercises
        .expand((exercise) => exercise.sections)
        .where((section) => section.label == 'Coach voice')
        .toList();

    expect(coachVoiceSections, hasLength(12));
    expect(
        coachVoiceSections.every((section) => section.text.trim().isNotEmpty),
        isTrue);
    print('Chapter 1 Coach voice sections: ${coachVoiceSections.length}');
  });

  testWidgets('App builds and shows splash screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LanSpeechApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
