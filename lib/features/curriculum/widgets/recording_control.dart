import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'package:lanspeech/core/constants/colors.dart';

/// Recording control for exercises where the client's document specifies a
/// microphone step (🎙️ Start Recording / ▶️ Play / 🔄 Record Again).
///
/// Handles mic permission, start/stop, an optional countdown against
/// [maxDuration] (parsed from the client's own text, e.g. "up to 60
/// seconds"), and playback of the just-made recording.
///
/// This captures and plays back locally only — it does not upload or
/// analyze audio. That belongs to the separate AI speech-analysis module
/// planned earlier; keeping it separate here matches what the curriculum
/// document actually asks for at this stage (no scoring, no AI feedback in
/// this core practice flow).
class RecordingControl extends StatefulWidget {
  final Duration? maxDuration;
  final bool isOptional;
  final void Function(String path, Duration duration)? onRecordingSaved;

  const RecordingControl({
    super.key,
    this.maxDuration,
    this.isOptional = false,
    this.onRecordingSaved,
  });

  @override
  State<RecordingControl> createState() => _RecordingControlState();
}

enum _RecordingPhase { idle, recording, recorded }

class _RecordingControlState extends State<RecordingControl> {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  _RecordingPhase _phase = _RecordingPhase.idle;
  String? _filePath;
  Duration _elapsed = Duration.zero;
  Timer? _timer;
  bool _isPlaying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    setState(() => _errorMessage = null);

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        setState(() {
          _errorMessage =
              'Microphone permission is needed to record this exercise.';
        });
        return;
      }
    }

    try {
      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/lanspeech_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(const RecordConfig(), path: path);

      setState(() {
        _phase = _RecordingPhase.recording;
        _filePath = path;
        _elapsed = Duration.zero;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _elapsed += const Duration(seconds: 1));
        final max = widget.maxDuration;
        if (max != null && _elapsed >= max) {
          _stopRecording();
        }
      });
    } catch (_) {
      setState(() {
        _errorMessage = "We couldn't start recording. Please try again.";
      });
    }
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    try {
      await _recorder.stop();
      if (!mounted) return;
      setState(() => _phase = _RecordingPhase.recorded);
      final path = _filePath;
      if (path != null) {
        widget.onRecordingSaved?.call(path, _elapsed);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "We couldn't save your recording. Please try again.";
      });
    }
  }

  Future<void> _playRecording() async {
    final path = _filePath;
    if (path == null) return;
    setState(() => _isPlaying = true);
    await _player.play(DeviceFileSource(path));
    _player.onPlayerComplete.first.then((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  Future<void> _recordAgain() async {
    setState(() {
      _phase = _RecordingPhase.idle;
      _filePath = null;
      _elapsed = Duration.zero;
    });
    await _startRecording();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF194148) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_errorMessage != null) ...[
            Text(
              _errorMessage!,
              style: GoogleFonts.poppins(color: AppColors.error, fontSize: 12),
            ),
            const SizedBox(height: 8),
          ],
          if (_phase == _RecordingPhase.idle)
            ElevatedButton.icon(
              onPressed: _startRecording,
              icon: const Icon(Icons.mic_rounded),
              label: Text(
                widget.isOptional
                    ? 'Start Recording (Optional)'
                    : 'Start Recording',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: AppColors.white,
              ),
            )
          else if (_phase == _RecordingPhase.recording) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.fiber_manual_record_rounded,
                    color: AppColors.error, size: 16),
                const SizedBox(width: 8),
                Text(
                  widget.maxDuration != null
                      ? '${_formatDuration(_elapsed)} / ${_formatDuration(widget.maxDuration!)}'
                      : _formatDuration(_elapsed),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.white : AppColors.navy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _stopRecording,
              icon: const Icon(Icons.stop_rounded),
              label: const Text('Stop Recording'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
              ),
            ),
          ] else ...[
            Text(
              'Your recording',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? AppColors.white : AppColors.navy,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPlaying ? null : _playRecording,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(_isPlaying ? 'Playing…' : 'Play'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _recordAgain,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Record Again'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
