import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:lanspeech/core/services/supabase_service.dart';
import 'package:lanspeech/features/auth/providers/auth_provider.dart';
import 'package:lanspeech/features/curriculum/models/speech_analysis_result.dart';

/// Sends a completed recording for AI analysis and returns a transcript +
/// short coach-style feedback message.
///
/// Deliberately does NOT call OpenAI (or any third-party AI API) directly
/// from the Flutter app — that would mean shipping a secret API key inside
/// the compiled app, extractable by anyone via decompilation or traffic
/// inspection. Instead this:
///   1. Uploads the local recording to a Supabase Storage bucket
///      ('speech-recordings', scoped to the signed-in user's own folder).
///   2. Invokes a Supabase Edge Function ('analyze-recording') with the
///      storage path plus exercise context. The Edge Function — which
///      runs server-side, not on the user's device — downloads the file,
///      calls OpenAI's Whisper (speech-to-text) and a chat completion for
///      feedback, and returns { transcript, feedback }. The OpenAI API key
///      lives only as a Supabase secret on that function, never in this
///      app. See the Edge Function source and setup steps delivered
///      alongside this file — deploying it is a required setup step this
///      repository depends on but cannot do on its own.
class SpeechAnalysisRepository {
  final SupabaseService _supabaseService;

  SpeechAnalysisRepository(this._supabaseService);

  Future<SpeechAnalysisResult> analyzeRecording({
    required String localAudioPath,
    required String exerciseTitle,
    required String exerciseContext,
    required String exerciseId,
    required Duration recordingDuration,
  }) async {
    final client = _supabaseService.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('You must be signed in to analyze a recording.');
    }

    final file = File(localAudioPath);
    final fileBytes = await file.readAsBytes();
    final storagePath =
        'recordings/$userId/${DateTime.now().millisecondsSinceEpoch}.m4a';

    await client.storage.from('speech-recordings').uploadBinary(
          storagePath,
          fileBytes,
        );

    final response = await client.functions.invoke(
      'analyze-recording',
      body: {
        'storagePath': storagePath,
        'exerciseTitle': exerciseTitle,
        'exerciseContext': exerciseContext,
        'exerciseId': exerciseId,
        'recordingDurationSeconds': recordingDuration.inSeconds,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final detail = data is Map ? data['error'] : null;
      final stage = data is Map ? data['stage'] : null;
      throw Exception(
        'Speech analysis failed${stage == null ? '' : ' during $stage'}'
        '${detail == null ? ' (status ${response.status})' : ': $detail'}',
      );
    }

    final data = response.data;
    if (data is! Map || data['feedback'] == null) {
      throw Exception('Speech analysis did not return a result.');
    }

    return SpeechAnalysisResult(
      transcript: (data['transcript'] as String?) ?? '',
      feedback: data['feedback'] as String,
      speakingDurationSeconds:
          (data['speakingDurationSeconds'] as num?)?.toInt() ??
              recordingDuration.inSeconds,
      speakingPaceWpm: (data['speakingPaceWpm'] as num?)?.toDouble() ?? 0,
      pauseCount: (data['pauseCount'] as num?)?.toInt() ?? 0,
      hesitationCount: (data['hesitationCount'] as num?)?.toInt() ?? 0,
      fluency: (data['fluency'] as String?) ?? 'not_rated',
    );
  }
}

final speechAnalysisRepositoryProvider =
    Provider<SpeechAnalysisRepository>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return SpeechAnalysisRepository(supabaseService);
});
