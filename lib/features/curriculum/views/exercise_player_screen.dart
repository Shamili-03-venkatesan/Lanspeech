import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';
import 'package:lanspeech/core/widgets/custom_button.dart';
import 'package:lanspeech/features/curriculum/models/chapter.dart';
import 'package:lanspeech/features/curriculum/models/completion_message.dart';
import 'package:lanspeech/features/curriculum/models/exercise.dart';
import 'package:lanspeech/features/curriculum/models/exercise_section.dart';
import 'package:lanspeech/features/curriculum/providers/curriculum_progress_provider.dart';
import 'package:lanspeech/features/curriculum/providers/practice_activity_provider.dart';
import 'package:lanspeech/features/curriculum/repository/curriculum_repository.dart';
import 'package:lanspeech/features/curriculum/repository/speech_analysis_repository.dart';
import 'package:lanspeech/features/curriculum/widgets/coach_voice_player.dart';
import 'package:lanspeech/features/curriculum/widgets/exercise_hero_illustration.dart';
import 'package:lanspeech/features/curriculum/widgets/exercise_progress_header.dart';
import 'package:lanspeech/features/curriculum/widgets/ready_to_continue_card.dart';
import 'package:lanspeech/features/curriculum/widgets/recording_control.dart';
import 'package:lanspeech/features/curriculum/widgets/reflection_picker.dart';
import 'package:lanspeech/features/gamification/providers/gamification_provider.dart';
import 'package:lanspeech/features/gamification/exceptions/xp_limit_exception.dart';
import 'package:lanspeech/features/profile/providers/subscription_provider.dart';

/// The single reusable screen that plays every one of the 120 exercises in
/// the LanSpeech curriculum, across all 10 chapters. Behavior and layout
/// for a given exercise are entirely data-driven off [Exercise.sections]
/// and its derived helpers — this screen contains no per-chapter or
/// per-exercise branching logic, so the visual design system established
/// here (progress header, hero illustration, coach card, ready-to-continue
/// card) automatically applies identically to every chapter, not just
/// Chapter 1.
///
/// Important UI rule: the client document's internal field labels ("What
/// the user sees", "User action", "Coach voice", "Completion screen",
/// etc.) exist to document requirements only. None of those labels are
/// rendered here — content is presented as natural flowing app copy, coach
/// paragraphs are played as audio rather than shown as text, and purely
/// procedural narration ("The user speaks the sentence aloud.") is left
/// out entirely since it's redundant with the interactive controls already
/// on screen.
class ExercisePlayerScreen extends ConsumerWidget {
  final int chapterNumber;
  final int exerciseNumber;

  const ExercisePlayerScreen({
    super.key,
    required this.chapterNumber,
    required this.exerciseNumber,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chaptersAsync = ref.watch(curriculumProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.navy : AppColors.offWhite,
      body: SafeArea(
        child: chaptersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => const _ErrorState(
            message: "We couldn't load this exercise. Please try again.",
          ),
          data: (chapters) {
            Chapter? chapter;
            for (final c in chapters) {
              if (c.chapterNumber == chapterNumber) {
                chapter = c;
                break;
              }
            }
            final exercise = chapter?.exerciseByNumber(exerciseNumber);

            if (chapter == null || exercise == null) {
              return const _ErrorState(
                message: "This exercise couldn't be found.",
              );
            }

            // Keyed by the exercise's internalId so Flutter always treats a
            // different exercise as a genuinely new widget subtree — this
            // guarantees CoachVoicePlayer (and the recording/reflection
            // controls) get fresh State per exercise rather than
            // potentially being reused/updated in place, which is what let
            // Exercise 1's already-spoken Coach Voice audio silently "stick"
            // instead of playing each subsequent exercise's own text.
            return _ExerciseContent(
              key: ValueKey(exercise.internalId),
              chapters: chapters,
              chapter: chapter,
              exercise: exercise,
            );
          },
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 40, color: AppColors.error),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Go Back',
              onPressed: () => context.pop(),
            ),
          ],
        ),
      ),
    );
  }
}

/// Finds the first section whose label matches [labelLower] (case-
/// insensitive, trimmed, trailing colon ignored). Returns null if no such
/// section exists — not every exercise has every field.
ExerciseSection? _findSection(
    List<ExerciseSection> sections, String labelLower) {
  for (final s in sections) {
    if (s.label.trim().toLowerCase().replaceAll(':', '') == labelLower) {
      return s;
    }
  }
  return null;
}

/// Labels that describe the interaction procedurally in the client's
/// document ("The user taps: Start Recording", "The user speaks the
/// sentence aloud.") rather than content the person should read. These are
/// intentionally not rendered anywhere — the interactive controls already
/// on screen (recording button, reflection chips, Continue) are the actual
/// "user action", per the client's explicit instruction to use natural
/// buttons/interactions instead of a documentation section.
const Set<String> _proceduralLabels = {
  'user action',
  'your turn',
  'your turn 🎙️',
};

/// Labels consumed by [ReadyToContinueCard] instead of being shown as a
/// plain paragraph in the main content flow.
const Set<String> _completionLabels = {
  'completion message',
  'completion screen',
  'final message',
  'final screen',
  'button',
};

/// State of AI analysis for a required-recording exercise's most recent
/// recording. Only meaningful when [_ExerciseContentState._requiresRecording]
/// is true.
enum _AnalysisState { idle, analyzing, success, error }

class _ExerciseContent extends ConsumerStatefulWidget {
  final List<Chapter> chapters;
  final Chapter chapter;
  final Exercise exercise;

  const _ExerciseContent({
    super.key,
    required this.chapters,
    required this.chapter,
    required this.exercise,
  });

  @override
  ConsumerState<_ExerciseContent> createState() => _ExerciseContentState();
}

class _ExerciseContentState extends ConsumerState<_ExerciseContent> {
  /// Whether the bottom ready-to-continue card is revealed yet.
  ///
  /// - No recording, no reflection (pure "listen, then continue"): starts
  ///   hidden, appears once the coach audio finishes.
  /// - Recording exercises: starts hidden and appears after a recording is
  ///   successfully completed (see [_recordingCompleted] below). Analysis
  ///   runs in the background to enrich the coach message box.
  /// - Everything else (optional recording, reflection, or both): starts
  ///   available immediately — the user's own action is what's being
  ///   waited on, and Continue is never blocked by audio playback for
  ///   these, consistent with not inventing enforcement the client never
  ///   specified.
  late bool _readyToContinue;

  /// Whether this exercise contains a recording step. Every recording step
  /// must be completed before the success box or Continue is shown.
  late final bool _requiresRecording;

  /// True the moment a required recording is successfully saved — drives
  /// the "Great!" confirmation box shown directly below the recording
  /// controls, independent of AI analysis state.
  bool _recordingCompleted = false;

  _AnalysisState _analysisState = _AnalysisState.idle;
  String? _aiFeedback;
  String? _transcript;
  String? _lastRecordingPath;
  Duration _recordingDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    final ex = widget.exercise;
    _requiresRecording = ex.involvesRecording;
    _readyToContinue = ex.involvesRecording ? false : ex.hasReflection;
  }

  /// Runs in the background after a recording is saved (and
  /// again on retry, or after "Record Again"). Purely enriches the coach
  /// message box with real feedback when it succeeds — does NOT gate
  /// _readyToContinue or _recordingCompleted, which are set the moment the
  /// recording itself finishes (see
  /// RecordingControl.onRecordingSaved below).
  Future<void> _runAiAnalysis(
      String audioPath, Duration recordingDuration) async {
    final primaryText =
        _findSection(widget.exercise.sections, 'what the user sees')?.text ??
            '';

    setState(() {
      _lastRecordingPath = audioPath;
      _recordingDuration = recordingDuration;
      _analysisState = _AnalysisState.analyzing;
      _aiFeedback = null;
      _transcript = null;
    });

    try {
      final result =
          await ref.read(speechAnalysisRepositoryProvider).analyzeRecording(
                localAudioPath: audioPath,
                exerciseTitle: widget.exercise.title,
                exerciseContext: primaryText,
                exerciseId: widget.exercise.internalId,
                recordingDuration: recordingDuration,
              );
      if (!mounted) return;
      setState(() {
        _aiFeedback = result.feedback;
        _transcript = result.transcript;
        _analysisState = _AnalysisState.success;
        _recordingCompleted = true;
        _readyToContinue = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _analysisState = _AnalysisState.error;
        _aiFeedback = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  void _retryAnalysis() {
    final path = _lastRecordingPath;
    if (path != null) {
      _runAiAnalysis(path, _recordingDuration);
    }
  }

  Future<void> _onContinue(String buttonLabel) async {
    final progressNotifier = ref.read(curriculumProgressProvider.notifier);
    final wasAlreadyComplete = ref
        .read(curriculumProgressProvider)
        .isExerciseComplete(widget.exercise.internalId);

    if (!wasAlreadyComplete) {
      // Check if user is premium and whether they can earn more XP
      final isPremium = await ref.read(isPremiumProvider.future);

      try {
        // Award XP and record today's practice date for the streak/calendar
        // only the first time this exercise is completed — replaying an
        // already-completed exercise (e.g. after navigating back) shouldn't
        // farm XP or artificially inflate the practice calendar.
        await ref.read(gamificationProvider.notifier).recordExerciseCompletion(
          isPremium: isPremium,
        );
      } on XpLimitReachedException catch (e) {
        // Free user reached XP limit
        if (!mounted) return;

        print('XP Limit reached: $e');

        // Navigate to Premium Upgrade screen
        context.push('/premium-upgrade');
        return;
      }
    }

    await progressNotifier.markExerciseComplete(widget.exercise.internalId);

    if (!mounted) return;

    final isLastExercise =
        widget.exercise.exerciseNumber >= widget.chapter.exercises.length;
    if (isLastExercise) {
      // Chapter complete — return to wherever the user entered from (e.g.
      // the dashboard). A dedicated chapter-completion screen can be added
      // later without changing this screen.
      context.pop();
    } else {
      context.pushReplacement(
        '/practice/${widget.chapter.chapterNumber}/${widget.exercise.exerciseNumber + 1}',
      );
    }
  }

  void _onPrevious() {
    if (widget.exercise.exerciseNumber > 1) {
      context.pushReplacement(
        '/practice/${widget.chapter.chapterNumber}/${widget.exercise.exerciseNumber - 1}',
      );
      return;
    }

    final previousChapter = widget.chapters
        .where(
            (chapter) => chapter.chapterNumber < widget.chapter.chapterNumber)
        .lastOrNull;
    if (previousChapter != null && previousChapter.exercises.isNotEmpty) {
      context.pushReplacement(
        '/practice/${previousChapter.chapterNumber}/${previousChapter.exercises.length}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chapter = widget.chapter;
    final exercise = widget.exercise;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = ref.watch(curriculumProgressProvider);
    final isComplete = progress.isExerciseComplete(exercise.internalId);

    final primarySection =
        _findSection(exercise.sections, 'what the user sees');
    final coachVoiceSection = _findSection(exercise.sections, 'coach voice');
    final otherTextSections = exercise.sections.where((s) {
      final label = s.label.trim().toLowerCase().replaceAll(':', '');
      return s.kind == ExerciseSectionKind.text &&
          s != primarySection &&
          s != coachVoiceSection &&
          !_proceduralLabels.contains(label) &&
          !_completionLabels.contains(label);
    }).toList();
    final reflectionSections = exercise.sections
        .where((s) => s.kind == ExerciseSectionKind.reflection)
        .toList();

    // A hero illustration is only shown for "listen and reflect" style
    // exercises with no other interactive control competing for visual
    // focus — when a recording or reflection control is present, that
    // control is the natural focal point instead.
    final showHero = !exercise.involvesRecording && !exercise.hasReflection;

    final completion = ParsedCompletion.fromSections(exercise.sections);
    // For a required-recording exercise, once AI analysis has produced
    // real feedback based on what the user actually said, that feedback
    // — not the client's static completion line — is what the coach
    // message box shows. Every other exercise (including a
    // required-recording one before analysis finishes) still shows the
    // client's own completion message, unchanged.
    final cardMessage = (_requiresRecording &&
            _analysisState == _AnalysisState.success &&
            (_aiFeedback ?? '').trim().isNotEmpty)
        ? _aiFeedback!.trim()
        : completion.message;

    return Column(
      children: [
        ExerciseProgressHeader(
          chapterNumber: chapter.chapterNumber,
          exerciseNumber: exercise.exerciseNumber,
          totalExercises: chapter.exercises.length,
          onBack: () => context.pop(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showHero) ...[
                  Center(child: const ExerciseHeroIllustration()),
                  const SizedBox(height: 24),
                ],
                if (isComplete) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        'Completed',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (primarySection != null) ...[
                  _PlainParagraph(
                    text: primarySection.text,
                    emphasized: true,
                    centered: showHero,
                  ),
                  const SizedBox(height: 20),
                ],
                if (coachVoiceSection != null) ...[
                  CoachVoicePlayer(
                    text: coachVoiceSection.text,
                    autoPlay: true,
                    onComplete: () {
                      // For required-recording exercises, Continue stays
                      // gated on the recording itself (see
                      // RecordingControl.onRecordingSaved below) — the
                      // coach finishing speaking must not unlock it early.
                      if (mounted && !_requiresRecording && !_readyToContinue) {
                        setState(() => _readyToContinue = true);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
                for (final section in otherTextSections) ...[
                  _PlainParagraph(text: section.text),
                  const SizedBox(height: 16),
                ],
                for (final section in reflectionSections) ...[
                  ReflectionPicker(section: section),
                  const SizedBox(height: 16),
                ],
                if (exercise.involvesRecording) ...[
                  RecordingControl(
                    maxDuration: exercise.maxRecordingDuration,
                    isOptional: false,
                    onRecordingSaved: (path, duration) {
                      // Recording is mandatory for a required-recording
                      // exercise: the moment it's successfully saved,
                      // unlock Continue and show the "Great!"
                      // confirmation — this does NOT wait on AI analysis.
                      // Optional/no-recording exercises are untouched:
                      // this whole callback only matters when
                      // _requiresRecording is true.
                      if (exercise.involvesRecording) {
                        ref
                            .read(practiceActivityProvider.notifier)
                            .recordSession(duration);
                        // Runs in the background purely to enrich the
                        // coach message box later — never blocks Continue.
                        _runAiAnalysis(path, duration);
                      }
                    },
                  ),
                  if (exercise.involvesRecording && _recordingCompleted) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Great!',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? AppColors.white : AppColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_requiresRecording &&
                      _analysisState == _AnalysisState.analyzing) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Analyzing your voice…',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.lightBackground.withOpacity(0.7)
                                : AppColors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_requiresRecording &&
                      _analysisState == _AnalysisState.error) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: AppColors.error, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _aiFeedback ??
                                "We couldn't analyze your recording.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _retryAnalysis,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                  if (_requiresRecording &&
                      _transcript != null &&
                      _transcript!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'You said: "${_transcript!.trim()}"',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: isDark
                            ? AppColors.lightBackground.withOpacity(0.6)
                            : AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
        if (widget.chapter.chapterNumber > 1 ||
            widget.exercise.exerciseNumber > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Previous'),
              ),
            ),
          ),
        AnimatedOpacity(
          opacity: _readyToContinue ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: IgnorePointer(
            ignoring: !_readyToContinue,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ReadyToContinueCard(
                message: cardMessage,
                buttonLabel: completion.buttonLabel,
                onContinue: () => _onContinue(completion.buttonLabel),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A block of exercise copy with no field label, no border, and no box —
/// just readable, naturally flowing text, the way a real app presents
/// content rather than a requirements document.
class _PlainParagraph extends StatelessWidget {
  final String text;
  final bool emphasized;
  final bool centered;

  const _PlainParagraph({
    required this.text,
    this.emphasized = false,
    this.centered = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: centered ? TextAlign.center : TextAlign.left,
      style: GoogleFonts.poppins(
        fontSize: emphasized ? 19 : 14,
        fontWeight: emphasized ? FontWeight.w600 : FontWeight.w400,
        height: 1.6,
        color: isDark ? AppColors.white : AppColors.navy,
      ),
    );
  }
}
