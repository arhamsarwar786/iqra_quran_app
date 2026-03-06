import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../Models/aya_list_model.dart';
import '../Services/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  int? _currentAyahIndex;
  PlayerState? _playerState;
  bool _isBuffering = false;
  String _currentSurahName = "";

  int? get currentAyahIndex => _currentAyahIndex;
  PlayerState? get playerState => _playerState;
  bool get isBuffering => _isBuffering;
  bool get isPlaying => _audioService.isPlaying;
  String get currentSurahName => _currentSurahName;

  AudioProvider() {
    _audioService.init();
    _audioService.currentAyahIndexStream.listen((index) {
      _currentAyahIndex = index;
      notifyListeners();
    });
    _audioService.playerStateStream.listen((state) {
      _playerState = state;
      notifyListeners();
    });
    _audioService.isBufferingStream.listen((buffering) {
      _isBuffering = buffering;
      notifyListeners();
    });
  }

  Future<bool> checkConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<void> startSurahPlayback(
      BuildContext context, List<Aya> ayats, String surahName) async {
    final hasConn = await checkConnection();
    if (!hasConn) {
      _showNoInternetDialog(context);
      return;
    }

    _currentSurahName = surahName;
    await _audioService.playSurah(ayats);
  }

  void _showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: Colors.redAccent),
            SizedBox(width: 10),
            Text("Connection Required"),
          ],
        ),
        content: const Text(
          "To listen to the beautiful recitation, an active internet connection is required. Please check your connection and try again.",
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> pausePlayback() async => await _audioService.pauseAudio();
  Future<void> resumePlayback() async => await _audioService.resumeAudio();
  Future<void> stopPlayback() async {
    await _audioService.stop();
    _currentSurahName = "";
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }
}
