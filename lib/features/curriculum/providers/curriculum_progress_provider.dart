import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/models/chapter.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/features/curriculum/repository/progress_repository.dart';

/// Tracks which exercises the user has completed.
/// Data is synced to Supabase as the source of truth, with SharedPreferences
/// as an offline cache. When user logs in on a new device, this fetches
/// their completed exercises from Supabase.
class CurriculumProgressState {
  final Set<String> completedExerciseIds;
  final bool isInitialized;
  final bool isSyncing;

  const CurriculumProgressState({
    required this.completedExerciseIds,
    this.isInitialized = false,
    this.isSyncing = false,
  });

  factory CurriculumProgressState.initial() => const CurriculumProgressState(
        completedExerciseIds: {},
        isInitialized: false,
        isSyncing: false,
      );

  bool isExerciseComplete(String internalId) =>
      completedExerciseIds.contains(internalId);

  int completedCountForChapter(Chapter chapter) => chapter.exercises
      .where((ex) => completedExerciseIds.contains(ex.internalId))
      .length;

  bool isChapterComplete(Chapter chapter) =>
      chapter.exercises.isNotEmpty &&
      completedCountForChapter(chapter) == chapter.exercises.length;

  CurriculumProgressState copyWith({
    Set<String>? completedExerciseIds,
    bool? isInitialized,
    bool? isSyncing,
  }) {
    return CurriculumProgressState(
      completedExerciseIds: completedExerciseIds ?? this.completedExerciseIds,
      isInitialized: isInitialized ?? this.isInitialized,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class CurriculumProgressNotifier
    extends StateNotifier<CurriculumProgressState> {
  static const String _prefsKey = 'curriculum_completed_exercise_ids';

  final SharedPreferences _prefs;
  final ProgressRepository _progressRepository;
  final SupabaseService _supabaseService;

  CurriculumProgressNotifier(this._prefs, this._progressRepository, this._supabaseService)
      : super(CurriculumProgressState.initial()) {
    _initialize();
  }

  /// Initialize: load from cloud first, fallback to local cache
  Future<void> _initialize() async {
    // CRITICAL: If user is not authenticated, clear cache to prevent
    // multi-user data leaks when switching accounts on same device
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) {
      state = CurriculumProgressState.initial();
      await _prefs.remove(_prefsKey);
      return;
    }

    state = state.copyWith(isSyncing: true);

    // Try to load from cloud (Supabase)
    final cloudData = await _progressRepository.fetchCompletedExercises();

    if (cloudData.isNotEmpty) {
      // Cloud has data — use it and update local cache
      state = state.copyWith(completedExerciseIds: cloudData);
      await _prefs.setStringList(_prefsKey, cloudData.toList());
    } else {
      // Cloud is empty — try local cache as fallback
      final cachedData = _prefs.getStringList(_prefsKey) ?? const <String>[];
      state = state.copyWith(completedExerciseIds: cachedData.toSet());

      // If we have local data and no cloud data, sync it to cloud
      if (cachedData.isNotEmpty) {
        await _progressRepository.syncCompletedExercises(cachedData.toSet());
      }
    }

    state = state.copyWith(isInitialized: true, isSyncing: false);
  }

  /// Mark exercise as complete: update state, local cache, AND cloud
  Future<void> markExerciseComplete(String internalId) async {
    final updated = {...state.completedExerciseIds, internalId};
    state = state.copyWith(completedExerciseIds: updated);

    // Update local cache
    await _prefs.setStringList(_prefsKey, updated.toList());

    // Sync to cloud (fire and forget, but print errors)
    state = state.copyWith(isSyncing: true);
    final success = await _progressRepository.markExerciseComplete(internalId);
    state = state.copyWith(isSyncing: false);

    if (!success) {
      print('Warning: Failed to sync exercise completion to cloud');
    }
  }

  /// For QA/testing only — clears all tracked progress locally and in cloud.
  Future<void> resetAll() async {
    state = CurriculumProgressState.initial();
    await _prefs.remove(_prefsKey);
    await _progressRepository.resetAll();
  }
}

final curriculumProgressProvider = StateNotifierProvider<
    CurriculumProgressNotifier, CurriculumProgressState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final progressRepo = ref.watch(progressRepositoryProvider);
  final supabaseService = ref.watch(supabaseServiceProvider);
  
  // Watch auth state so we reinitialize when user logs in/out
  ref.watch(authProvider);

  return CurriculumProgressNotifier(prefs, progressRepo, supabaseService);
});

/// Where the user should resume practice: the first chapter that isn't yet
/// fully complete, and within it, the first exercise not yet completed —
/// Chapter 1 Exercise 1 if nothing has been completed yet. This is what
/// the Dashboard's "Start Practice" / "Continue Your Practice" button uses
/// to decide both its label and where tapping it should navigate.
class ResumePoint {
  final int chapterNumber;
  final int exerciseNumber;
  final bool hasStartedAnyPractice;

  const ResumePoint({
    required this.chapterNumber,
    required this.exerciseNumber,
    required this.hasStartedAnyPractice,
  });
}

/// Derived purely from [curriculumProvider] (the bundled chapter/exercise
/// list, already in order) and [curriculumProgressProvider] (local
/// completion state) — no separate persisted "current position" is stored
/// anywhere, so this can never drift out of sync with actual completion.
/// Because it watches curriculumProgressProvider, it automatically
/// recomputes every time an exercise is marked complete (see
/// ExercisePlayerScreen._onContinue), with no extra wiring needed for the
/// Dashboard to reflect the latest position next time it's shown.
final resumePointProvider = Provider<AsyncValue<ResumePoint>>((ref) {
  final chaptersAsync = ref.watch(curriculumProvider);
  final progress = ref.watch(curriculumProgressProvider);

  return chaptersAsync.whenData((chapters) {
    for (final chapter in chapters) {
      for (final exercise in chapter.exercises) {
        if (!progress.isExerciseComplete(exercise.internalId)) {
          return ResumePoint(
            chapterNumber: chapter.chapterNumber,
            exerciseNumber: exercise.exerciseNumber,
            hasStartedAnyPractice: progress.completedExerciseIds.isNotEmpty,
          );
        }
      }
    }
    // Every exercise in every chapter is complete — resume at the very
    // last exercise rather than falling off the end of the list.
    final lastChapter = chapters.isNotEmpty ? chapters.last : null;
    return ResumePoint(
      chapterNumber: lastChapter?.chapterNumber ?? 1,
      exerciseNumber: lastChapter?.exercises.length ?? 1,
      hasStartedAnyPractice: true,
    );
  });
});
