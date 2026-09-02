import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// Plays a "Coach voice" paragraph as spoken audio via on-device
/// text-to-speech, standing in for real recorded coach audio until the
/// client provides voiced assets (see the curriculum analysis's open
/// clarification on voice/locale).
///
/// The paragraph itself is intentionally never rendered as text on screen —
/// only a glowing play control flanked by decorative soundwave bars, with a
/// short status line underneath. This is the shared "coach card" visual
/// used everywhere a Coach Voice section appears, across every chapter.
class CoachVoicePlayer extends StatefulWidget {
  final String text;
  final bool autoPlay;
  final VoidCallback? onComplete;

  const CoachVoicePlayer({
    super.key,
    required this.text,
    this.autoPlay = true,
    this.onComplete,
  });

  @override
  State<CoachVoicePlayer> createState() => _CoachVoicePlayerState();
}

class _CoachVoicePlayerState extends State<CoachVoicePlayer> {
  static final FlutterTts _tts = FlutterTts();
  static _CoachVoicePlayerState? _activePlayer;

  bool _isSpeaking = false;
  bool _hasPlayed = false;
  bool _errored = false;

  @override
  void initState() {
    super.initState();
    _activePlayer = this;
    _tts.setCompletionHandler(() {
      if (!mounted || _activePlayer != this) return;
      setState(() {
        _isSpeaking = false;
        _hasPlayed = true;
      });
      widget.onComplete?.call();
    });
    _tts.setErrorHandler((dynamic _) {
      if (!mounted || _activePlayer != this) return;
      setState(() {
        _isSpeaking = false;
        _errored = true;
      });
      // Don't strand the user on a device where TTS isn't available —
      // let the flow continue as if the coach had finished speaking.
      widget.onComplete?.call();
    });
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _play();
      });
    }
  }

  @override
  void didUpdateWidget(covariant CoachVoicePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Defensive fix, independent of the exercise-identity key applied where
    // this widget is used: initState() only runs once per State object, so
    // if this widget's text ever changes without a new State being created
    // (a different exercise's Coach Voice content arriving into what
    // Flutter treated as "the same" widget), the old State would otherwise
    // just sit there having already spoken the previous exercise's line
    // and never play the new one. Explicitly react to a text change here
    // so playback is always tied to the exercise currently being shown.
    if (oldWidget.text != widget.text) {
      _tts.stop();
      setState(() {
        _isSpeaking = false;
        _hasPlayed = false;
        _errored = false;
      });
      if (widget.autoPlay) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _play();
        });
      }
    }
  }

  Future<void> _play() async {
    if (!mounted || _activePlayer != this || _isSpeaking) return;
    // Clear any lingering utterance from a previous exercise before
    // starting this one, so playback never silently overlaps or gets
    // dropped by the native engine mid-transition.
    await _tts.stop();
    // flutter_tts updates the web/native speaking state from its platform
    // callback. Give that callback a turn to complete before issuing the
    // next utterance during an exercise transition.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    setState(() {
      _isSpeaking = true;
      _errored = false;
    });
    try {
      await _tts.awaitSpeakCompletion(true);
      await _tts.setLanguage('en-US');
      // A slightly slower, calmer pace suits a supportive coach persona
      // better than the default speaking rate.
      await _tts.setSpeechRate(0.45);
      await _tts.setPitch(1.0);
      await _tts.speak(widget.text);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSpeaking = false;
        _errored = true;
      });
      widget.onComplete?.call();
    }
  }

  @override
  void dispose() {
    // Route replacement can dispose the old page after the next page has
    // already initialized. Only the current page may stop shared TTS.
    if (_activePlayer == this) {
      _activePlayer = null;
      _tts.stop();
    }
    super.dispose();
  }

  String get _title {
    if (_errored) return 'Tap to hear your coach';
    if (_isSpeaking) return 'Listening to your coach…';
    if (_hasPlayed) return 'Tap to hear that again';
    return 'Your coach is ready';
  }

  String get _subtitle {
    if (_errored) return "Audio isn't available on this device right now.";
    if (_hasPlayed && !_isSpeaking) return 'Replay anytime you like.';
    return 'Take a deep breath and enjoy the guidance.';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: _play,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF194148) : AppColors.lightBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _WaveCluster(active: _isSpeaking),
                const SizedBox(width: 18),
                _PlayGlowButton(isSpeaking: _isSpeaking),
                const SizedBox(width: 18),
                _WaveCluster(active: _isSpeaking),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isDark
                    ? AppColors.lightBackground.withOpacity(0.7)
                    : AppColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayGlowButton extends StatelessWidget {
  final bool isSpeaking;
  const _PlayGlowButton({required this.isSpeaking});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.teal,
        border: Border.all(color: AppColors.yellow, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.yellow.withOpacity(isSpeaking ? 0.55 : 0.35),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        isSpeaking ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
        color: AppColors.white,
        size: 26,
      ),
    );
  }
}

/// Small decorative soundwave bars flanking the play button — purely
/// visual audio-language cues, not a real waveform of the audio.
class _WaveCluster extends StatelessWidget {
  final bool active;
  const _WaveCluster({required this.active});

  static const List<double> _heights = [10, 20, 14, 24];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_heights.length, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          width: 3,
          height: _heights[i],
          decoration: BoxDecoration(
            color: AppColors.teal.withOpacity(active ? 0.9 : 0.35),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
