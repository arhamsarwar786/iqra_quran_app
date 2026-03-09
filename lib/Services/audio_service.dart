import 'dart:async';
import 'dart:developer';
import 'package:just_audio/just_audio.dart';
import '../Models/aya_list_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  final StreamController<int?> _currentAyahIndex =
      StreamController<int?>.broadcast();
  final StreamController<String?> _currentAyahId =
      StreamController<String?>.broadcast();
  final StreamController<int?> _currentAyahNumber =
      StreamController<int?>.broadcast();
  final StreamController<PlayerState> _playerState =
      StreamController<PlayerState>.broadcast();
  final StreamController<bool> _isBuffering =
      StreamController<bool>.broadcast();

  Stream<int?> get currentAyahIndexStream => _currentAyahIndex.stream;
  Stream<String?> get currentAyahIdStream => _currentAyahId.stream;
  Stream<int?> get currentAyahNumberStream => _currentAyahNumber.stream;
  Stream<PlayerState> get playerStateStream => _playerState.stream;
  Stream<bool> get isBufferingStream => _isBuffering.stream;

  List<Aya> _playlist = [];
  int _currentIndex = 0;
  int? _lastAyahIndex;
  String? _lastAyahId;
  int? _lastAyahNumber;

  void init() {
    _player.playerStateStream.listen((state) {
      _playerState.add(state);
      _isBuffering.add(state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading);

      if (state.processingState == ProcessingState.completed) {
        _playNext();
      }
    });
  }

  Future<void> playSurah(List<Aya> ayats,
      {String? startAyatId, int? startIndex}) async {
    // Determine the target ID to start at
    String? targetId = startAyatId;
    if (targetId == null &&
        startIndex != null &&
        startIndex >= 0 &&
        startIndex < ayats.length) {
      targetId = ayats[startIndex].ayatId;
    }

    // Always skip Bismillah (ayatNumber "0") in the active playlist.
    // Track 1 for Alafasy is S1 V1 (Alhamdulillah), which contains the Bismillah intro.
    _playlist = ayats.where((a) => a.ayatNumber != "0").toList();

    if (targetId != null) {
      _currentIndex = _playlist.indexWhere((a) => a.ayatId == targetId);
      // Fallback: If targetId (e.g. Bismillah) was filtered out, start at the first available verse
      if (_currentIndex == -1) _currentIndex = 0;
    } else {
      _currentIndex = 0;
    }

    if (_playlist.isEmpty) return;
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      stop();
      return;
    }

    final aya = _playlist[_currentIndex];
    _lastAyahId = aya.ayatId;
    _lastAyahNumber = aya.ayatNumberInt;
    _currentAyahId.add(_lastAyahId);
    _currentAyahNumber.add(_lastAyahNumber);

    String globalTrackIndex = aya.ayatId ?? "1";
    // debugger();
    final String audioUrl =
        "https://cdn.islamic.network/quran/audio/128/ar.alafasy/$globalTrackIndex.mp3";

    try {
      _lastAyahIndex = _currentIndex;
      _currentAyahIndex.add(_currentIndex);
      await _player.setUrl(audioUrl);
      _player.play();
    } catch (e) {
      print("Audio Service Error: $e");
      _playNext();
    }
  }

  void _playNext() {
    if (_currentIndex < _playlist.length - 1) {
      _currentIndex++;
      _playCurrent();
    } else {
      stop();
    }
  }

  Future<void> pauseAudio() async => await _player.pause();
  Future<void> resumeAudio() async => await _player.play();

  Future<void> stop() async {
    await _player.stop();
    _lastAyahIndex = null;
    _lastAyahId = null;
    _lastAyahNumber = null;
    _currentAyahIndex.add(null);
    _currentAyahId.add(null);
    _currentAyahNumber.add(null);
    _currentIndex = 0;
  }

  int? get currentAyahIndex => _lastAyahIndex;
  String? get currentAyahId => _lastAyahId;
  int? get currentAyahNumber => _lastAyahNumber;
  bool get isPlaying => _player.playing;

  void dispose() {
    _player.dispose();
    _currentAyahIndex.close();
    _currentAyahId.close();
    _currentAyahNumber.close();
    _playerState.close();
    _isBuffering.close();
  }
}
