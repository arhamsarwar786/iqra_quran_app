import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Provider/theme_provider.dart';
import '../Services/audio_service.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _audioService = AudioService();

  int? _currentAyahIndex;
  String? _currentAyahId;
  int? _currentAyahNumber;
  PlayerState? _playerState;
  bool _isBuffering = false;
  String _currentSurahName = "";

  int? get currentAyahIndex => _currentAyahIndex;
  String? get currentAyahId => _currentAyahId;
  int? get currentAyahNumber => _currentAyahNumber;
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
    _audioService.currentAyahIdStream.listen((id) {
      _currentAyahId = id;
      notifyListeners();
    });
    _audioService.currentAyahNumberStream.listen((num) {
      _currentAyahNumber = num;
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
      BuildContext context, List<Aya> ayats, String surahName,
      {String? startAyatId, int? startIndex}) async {
    final hasConn = await checkConnection();
    if (!hasConn) {
      _showNoInternetDialog(context);
      return;
    }

    _currentSurahName = surahName;
    await _audioService.playSurah(ayats,
        startAyatId: startAyatId, startIndex: startIndex);
  }

  void _showNoInternetDialog(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: themeProvider.selectedTheme, width: 2)),
        title: Row(
          children: [
            Icon(Icons.wifi_off_rounded, color: themeProvider.selectedTheme),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                "Connection Required",
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ),
          ],
        ),
        content: const Text(
          "To listen to the beautiful recitation, an active internet connection is required. Please check your connection and try again.",
          style: TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: themeProvider.selectedTheme.withOpacity(0.1),
              foregroundColor: themeProvider.selectedTheme,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
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
