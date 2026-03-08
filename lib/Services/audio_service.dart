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

  Future<void> playSurah(List<Aya> ayats, {int startIndex = 0}) async {
    String? targetId;

    if (startIndex >= 0 && startIndex < ayats.length) {
      targetId = ayats[startIndex].ayatId;
    }

    // Consistent filtering: Skip Bismillah (Verse 0) for all Surahs/Paras.
    // For Alafasy, Track 1 is S1 V1 (Alhamdulillah), which already includes Bismillah audio.
    _playlist = ayats.where((a) => a.ayatNumber != "0").toList();

    if (targetId != null) {
      _currentIndex = _playlist.indexWhere((a) => a.ayatId == targetId);
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

    // Track Mapping Logic:
    // Tracks 1-6236 in the API correspond to the verses of the Quran.
    // In this mapping, Fatiha Bismillah is Track 1.
    // For all other Surahs (2-114), Bismillah is NOT a track.
    // So we subtract the number of "extra" Bismillahs encountered before this verse.

    int surahIdInt = int.tryParse(aya.surahId ?? "1") ?? 1;

    // Number of extra Bismillahs (those NOT in the 1-6236 sequence):
    // Surah 1: Bismillah is Track 1. Count = 1.
    // Surah 2-8: surahId - count of bismillahs before or at this surah.
    // Correct Formula:
    // Before S1 V1 (Alhamdu), there is 1 extra (S1 Bismillah).
    // Before S2 V1, there are 2 extras (S1 Bismillah + S2 Bismillah).
    // Surah 9 has no Bismallah.

    int totalBismillahsBeforeOrAtS =
        surahIdInt < 9 ? surahIdInt : surahIdInt - 1;

    int globalTrackIndex =
        (int.tryParse(aya.ayatId ?? "1") ?? 1) - totalBismillahsBeforeOrAtS;

    // Since Tracks start at 1, if ID 2 (S1 V1) - 1 (S1 BM) = 1. Track 1 is S1 V1.
    // Track 8 is S2 V1. (ID 10 - 2 BM = 8). Correct.

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
