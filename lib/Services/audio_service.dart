import 'dart:async';
import 'package:just_audio/just_audio.dart';
import '../Models/aya_list_model.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _player = AudioPlayer();

  final StreamController<int?> _currentAyahIndex =
      StreamController<int?>.broadcast();
  final StreamController<PlayerState> _playerState =
      StreamController<PlayerState>.broadcast();
  final StreamController<bool> _isBuffering =
      StreamController<bool>.broadcast();

  Stream<int?> get currentAyahIndexStream => _currentAyahIndex.stream;
  Stream<PlayerState> get playerStateStream => _playerState.stream;
  Stream<bool> get isBufferingStream => _isBuffering.stream;

  List<Aya> _playlist = [];
  int _currentIndex = 0;
  int? _lastAyahIndex;

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

  Future<void> playSurah(List<Aya> ayats, {int startIndex = 0}) async {
    _playlist = ayats.where((a) => a.ayatNumber != "0").toList();
    _currentIndex = startIndex;
    if (_playlist.isEmpty) return;

    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_currentIndex < 0 || _currentIndex >= _playlist.length) {
      stop();
      return;
    }

    final aya = _playlist[_currentIndex];

    // Calculate global track index (1-6236)
    // Every surah except 9 has a Bismillah (ayatNumber "0") in the JSON
    int surahIdInt = int.tryParse(aya.surahId ?? "1") ?? 1;
    int bismillahsAtOrBefore = surahIdInt;
    if (surahIdInt >= 9) bismillahsAtOrBefore--;

    int globalTrackIndex =
        (int.tryParse(aya.ayatId ?? "1") ?? 1) - bismillahsAtOrBefore;

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
    _currentAyahIndex.add(null);
    _currentIndex = 0;
  }

  int? get currentAyahIndex => _lastAyahIndex;
  bool get isPlaying => _player.playing;

  void dispose() {
    _player.dispose();
    _currentAyahIndex.close();
    _playerState.close();
    _isBuffering.close();
  }
}
