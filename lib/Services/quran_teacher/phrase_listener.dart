import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:record/record.dart';

/// Listens while the learner recites a whole ayah, and hands over each
/// phrase they say between pauses as a WAV recording, so it can be checked
/// while they go on reciting.
class PhraseListener {
  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audio;

  static const int _rate = 16000;
  // Audio is measured in frames of 50 ms.
  static const int _frame = _rate ~/ 20;
  // Louder than this (dBFS) is speech; quieter, after speaking, is a pause.
  // The same levels as WordRecorder.
  static const double _speechDb = -32;
  static const double _quietDb = -42;
  // A pause this long ends a phrase.
  static const int _pauseFrames = 14; // 700 ms
  // Kept from before the speech started, so its first letter is not cut.
  static const int _leadFrames = 6; // 300 ms
  // Less speech than this is a click or a breath.
  static const int _minSpeechFrames = 5; // 250 ms
  // The server hears at most 30 s; a phrase never runs on that long.
  static const int _maxFrames = 20 * 20; // 20 s

  final StreamController<Uint8List> _phrases = StreamController.broadcast();
  final StreamController<double> _level = StreamController.broadcast();
  final StreamController<bool> _speaking = StreamController.broadcast();

  /// Each phrase, as a 16 kHz mono 16-bit WAV.
  Stream<Uint8List> get phrases => _phrases.stream;

  /// Loudness, 0 (quiet) to 1, about 20 times a second.
  Stream<double> get level => _level.stream;

  /// True while the learner is saying a phrase, false at each pause.
  Stream<bool> get speaking => _speaking.stream;

  bool get isListening => _audio != null;

  final BytesBuilder _pending = BytesBuilder(copy: false);
  final List<Uint8List> _lead = [];
  final BytesBuilder _phrase = BytesBuilder(copy: false);
  bool _inPhrase = false;
  int _phraseFrames = 0;
  int _speechFrames = 0;
  int _quietFrames = 0;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (_audio != null) return;
    _reset();
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _rate,
        numChannels: 1,
        // Phone noise suppression can swallow a held madd; keep it raw.
        noiseSuppress: false,
        echoCancel: false,
      ),
    );
    _audio = stream.listen(_onAudio);
  }

  /// Stops listening. A phrase still being said is dropped.
  Future<void> stop() async {
    final audio = _audio;
    if (audio == null) return;
    _audio = null;
    await audio.cancel();
    await _recorder.stop();
    _reset();
    _level.add(0);
    _speaking.add(false);
  }

  void _reset() {
    _pending.clear();
    _lead.clear();
    _phrase.clear();
    _inPhrase = false;
    _phraseFrames = _speechFrames = _quietFrames = 0;
  }

  void _onAudio(Uint8List data) {
    _pending.add(data);
    if (_pending.length < _frame * 2) return;
    final bytes = _pending.takeBytes();
    var offset = 0;
    while (bytes.length - offset >= _frame * 2) {
      _onFrame(Uint8List.sublistView(bytes, offset, offset + _frame * 2));
      offset += _frame * 2;
    }
    if (offset < bytes.length) {
      _pending.add(Uint8List.sublistView(bytes, offset));
    }
  }

  void _onFrame(Uint8List frame) {
    final db = _loudness(frame);
    _level.add(((db + 50) / 40).clamp(0.0, 1.0));

    if (!_inPhrase) {
      _lead.add(frame);
      if (_lead.length > _leadFrames) _lead.removeAt(0);
      if (db > _speechDb) {
        _inPhrase = true;
        for (final f in _lead) {
          _phrase.add(f);
        }
        _phraseFrames = _lead.length;
        _lead.clear();
        _speechFrames = 1;
        _quietFrames = 0;
        _speaking.add(true);
      }
      return;
    }

    _phrase.add(frame);
    _phraseFrames++;
    if (db > _speechDb) {
      _speechFrames++;
      _quietFrames = 0;
    } else if (db < _quietDb) {
      _quietFrames++;
    }
    if (_quietFrames >= _pauseFrames || _phraseFrames >= _maxFrames) {
      _endPhrase();
    }
  }

  void _endPhrase() {
    final pcm = _phrase.takeBytes();
    final spoke = _speechFrames >= _minSpeechFrames;
    _inPhrase = false;
    _phraseFrames = _speechFrames = _quietFrames = 0;
    _speaking.add(false);
    if (spoke) _phrases.add(_wav(pcm));
  }

  static double _loudness(Uint8List frame) {
    // Read through ByteData: the frame need not start on an even address.
    final data = ByteData.sublistView(frame);
    final count = frame.length ~/ 2;
    var sum = 0.0;
    for (var i = 0; i < count; i++) {
      final s = data.getInt16(i * 2, Endian.little);
      sum += s * s;
    }
    final rms = math.sqrt(sum / count) / 32768;
    return rms <= 0 ? -100 : 20 * math.log(rms) / math.ln10;
  }

  static Uint8List _wav(Uint8List pcm) {
    final header = ByteData(44);
    void ascii(int at, String text) {
      for (var i = 0; i < text.length; i++) {
        header.setUint8(at + i, text.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    header.setUint32(4, 36 + pcm.length, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little); // PCM
    header.setUint16(22, 1, Endian.little); // mono
    header.setUint32(24, _rate, Endian.little);
    header.setUint32(28, _rate * 2, Endian.little);
    header.setUint16(32, 2, Endian.little);
    header.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    header.setUint32(40, pcm.length, Endian.little);
    return (BytesBuilder(copy: false)
          ..add(header.buffer.asUint8List())
          ..add(pcm))
        .takeBytes();
  }

  Future<void> dispose() async {
    await stop();
    await _recorder.dispose();
    await _phrases.close();
    await _level.close();
    await _speaking.close();
  }
}
