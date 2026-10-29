import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Provider/quran_data_provider.dart';
import '../Provider/theme_provider.dart';
import '../Services/analytics_service.dart';
import '../Services/quran_audio_handler.dart';
import '../Services/recitation_downloads.dart';
import '../Services/recitation_playlist.dart';

class AudioProvider extends ChangeNotifier {
  final QuranAudioHandler _handler;
  final List<StreamSubscription> _subscriptions = [];

  MediaItem? _item;
  PlaybackState _state = PlaybackState();
  int _queueLength = 0;

  AudioProvider(this._handler) {
    _handler.reconnecting.addListener(notifyListeners);
    _subscriptions.addAll([
      _handler.mediaItem.listen((item) {
        _item = item;
        notifyListeners();
      }),
      _handler.playbackState.listen((state) {
        final changed = state.playing != _state.playing ||
            state.processingState != _state.processingState ||
            state.queueIndex != _state.queueIndex;
        _state = state;
        // Position updates arrive constantly; only rebuild on real changes.
        if (changed) notifyListeners();
      }),
      _handler.queue.listen((queue) {
        _queueLength = queue.length;
        notifyListeners();
      }),
    ]);
  }

  bool get isActive => _item != null;

  /// Queue position of the current recording, or null when nothing is loaded.
  int? get currentAyahIndex => _item?.extras?['index'] as int?;

  int? get currentSurahId => _item?.extras?['surahId'] as int?;

  /// Verse number as numbered in the app's data; 0 while Bismillah plays.
  int? get currentAyahNumber => _item?.extras?['ayahNumber'] as int?;

  List<String> get currentAyahIds =>
      (_item?.extras?['ayatIds'] as List?)?.cast<String>() ?? const [];

  /// First verse being recited, for scrolling the reading screens.
  String? get currentAyahId =>
      currentAyahIds.isEmpty ? null : currentAyahIds.first;

  /// Whether [ayatId] is in the recording playing now. Covers recordings that
  /// span two on-screen verses (Al-Fatiha 6-7).
  bool isReciting(String? ayatId) =>
      ayatId != null && currentAyahIds.contains(ayatId);

  bool get isBismillah => currentAyahNumber == 0;

  /// e.g. "5", or "6–7" when one recording covers two verses.
  String get currentAyahLabel =>
      _item?.extras?['ayahLabel'] as String? ?? '${currentAyahNumber ?? ''}';
  String get currentSurahName => _item?.album ?? "";

  /// e.g. "Ayah 5 of 7", "Bismillah" or "Reconnecting…".
  String ayahSubtitle(QuranDataProvider quran) {
    if (isReconnecting) return 'Reconnecting…';
    if (isBismillah) return 'Bismillah';
    final surahId = currentSurahId;
    final total = surahId == null
        ? null
        : quran.getSurahMetadata(surahId)?.surahTotalAyaat;
    return 'Ayah $currentAyahLabel'
        '${total != null && total > 0 ? ' of $total' : ''}';
  }
  String get currentTitle => _item?.title ?? "";
  int get queueLength => _queueLength;
  bool get isPlaying => _state.playing;
  bool get isBuffering =>
      _state.processingState == AudioProcessingState.loading ||
      _state.processingState == AudioProcessingState.buffering;

  /// True while a verse that failed to load is being retried.
  bool get isReconnecting => _handler.reconnecting.value;
  bool get hasNext => _handler.hasNext;
  bool get hasPrevious => _handler.hasPrevious;

  Stream<Duration> get positionStream => _handler.positionStream;
  Duration? get currentDuration => _item?.duration;

  Future<bool> checkConnection() async {
    try {
      // The host the recitation is streamed from.
      final result = await InternetAddress.lookup('everyayah.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// [RecitationPlaylist.keyOf] the queue loaded now, or null when nothing
  /// is loaded.
  String? get queueKey => isActive ? _queueKey : null;
  String? _queueKey;

  /// Key of the recitation [ayats] would start, to compare with [queueKey].
  static String queueKeyFor(List<Aya> ayats) =>
      RecitationPlaylist.keyOf(RecitationPlaylist.build(ayats));

  /// Whether [ayats] can be recited now: every verse is downloaded, or the
  /// device is online.
  Future<bool> canPlay(List<Aya> ayats) async {
    final downloads = RecitationDownloads.instance;
    final tracks = RecitationPlaylist.build(ayats);
    if (tracks.every((t) => downloads.isSaved(t.url))) return true;
    return checkConnection();
  }

  /// Recites [ayats] in order, starting at [startAyatId] (or [startIndex] in
  /// [ayats]). [surahTitle] names each surah for the notification; it
  /// defaults to [surahName], which suits single-surah lists. Downloaded
  /// verses play from the device, so a downloaded recitation needs no
  /// connection.
  Future<void> startSurahPlayback(List<Aya> ayats, String surahName,
      {BuildContext? context,
      String? startAyatId,
      int? startIndex,
      String Function(int surahId)? surahTitle}) async {
    final remote = RecitationPlaylist.build(ayats);
    if (remote.isEmpty) return;
    final downloads = RecitationDownloads.instance;
    final tracks = [for (final t in remote) t.withUrl(downloads.resolve(t.url))];

    if (!tracks.every((t) => t.isLocal) && !await checkConnection()) {
      if (context != null && context.mounted) {
        _showNoInternetDialog(context);
      }
      return;
    }

    final targetId = startAyatId ??
        (startIndex != null && startIndex >= 0 && startIndex < ayats.length
            ? ayats[startIndex].ayatId
            : null);

    AnalyticsService.logEvent('audio_played',
        parameters: {'surah_name': surahName});
    _queueKey = RecitationPlaylist.keyOf(remote);
    await _handler.playTracks(
      tracks,
      startIndex: RecitationPlaylist.startIndexFor(tracks, targetId),
      surahTitle: surahTitle ?? (_) => surahName,
    );
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
          "To listen to the beautiful recitation, an active internet connection is required. Please check your connection and try again.\n\nTip: tap the download button on any surah or para to listen offline.",
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

  Future<void> pausePlayback() => _handler.pause();
  Future<void> resumePlayback() => _handler.play();
  Future<void> togglePlayback() =>
      isPlaying ? pausePlayback() : resumePlayback();
  Future<void> skipNext() => _handler.skipToNext();
  Future<void> skipPrevious() => _handler.skipToPrevious();
  Future<void> stopPlayback() => _handler.stop();

  @override
  void dispose() {
    _handler.reconnecting.removeListener(notifyListeners);
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }
}
