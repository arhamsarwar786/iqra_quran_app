import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class WordRecording {
  final File file;

  /// False when nothing louder than the room was heard. Such a recording is
  /// not sent: the recognizer can mistake noise for a word.
  final bool spoke;

  const WordRecording(this.file, {required this.spoke});
}

/// Records the learner saying one word, and stops by itself once they have
/// spoken and gone quiet, so they never need to press stop.
class WordRecorder {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Amplitude>? _levels;

  // Louder than this (dBFS) is speech; quieter, after speaking, is the end.
  static const double _speechDb = -32;
  static const double _quietDb = -42;
  static const Duration _endSilence = Duration(milliseconds: 800);
  static const Duration _waitForSpeech = Duration(seconds: 6);
  static const Duration _maxLength = Duration(seconds: 9);

  /// Loudness while recording, 0 (quiet) to 1, for the microphone animation.
  final StreamController<double> _level = StreamController.broadcast();
  Stream<double> get level => _level.stream;

  Future<bool> hasPermission() => _recorder.hasPermission();

  /// Records until the learner finishes the word. Returns the recording, or
  /// null if [cancel] completes first.
  Future<WordRecording?> recordWord({Future<void>? cancel}) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/teacher_word.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        // Phone noise suppression can swallow a held madd; keep it raw.
        noiseSuppress: false,
        echoCancel: false,
      ),
      path: path,
    );

    final done = Completer<bool>();
    final started = DateTime.now();
    DateTime? spokeAt;
    DateTime? quietSince;

    _levels = _recorder
        .onAmplitudeChanged(const Duration(milliseconds: 80))
        .listen((amp) {
      final now = DateTime.now();
      _level.add(((amp.current + 50) / 40).clamp(0.0, 1.0));
      if (amp.current > _speechDb) {
        spokeAt ??= now;
        quietSince = null;
      } else if (spokeAt != null && amp.current < _quietDb) {
        quietSince ??= now;
        if (now.difference(quietSince!) >= _endSilence) {
          if (!done.isCompleted) done.complete(true);
        }
      }
      final elapsed = now.difference(started);
      if (elapsed >= _maxLength ||
          (spokeAt == null && elapsed >= _waitForSpeech)) {
        if (!done.isCompleted) done.complete(true);
      }
    });
    cancel?.then((_) {
      if (!done.isCompleted) done.complete(false);
    });

    final keep = await done.future;
    await _levels?.cancel();
    _levels = null;
    _level.add(0);
    final file = await _recorder.stop();
    if (!keep || file == null) return null;
    return WordRecording(File(file), spoke: spokeAt != null);
  }

  Future<void> dispose() async {
    await _levels?.cancel();
    if (await _recorder.isRecording()) await _recorder.stop();
    await _recorder.dispose();
    await _level.close();
  }
}
