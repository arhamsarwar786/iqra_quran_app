import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'recitation_playlist.dart';

/// Plays a recitation queue and publishes it to the platform media session,
/// which drives the notification, lock screen, Bluetooth/headset buttons and
/// Android Auto/Wear controls.
///
/// Every queue item is a [MediaItem] whose `extras` carry the verse ids it
/// covers, so the UI highlights exactly what the player is on.
class QuranAudioHandler extends BaseAudioHandler with SeekHandler {
  static const String closeAction = 'close';
  static const String _artworkAsset = 'assets/images/iqra-white-logo.png';

  // Automatic retries for a verse that fails to load, 2s, 4s, 8s, 16s and
  // 32s apart. After that playback pauses on the verse until the network
  // returns or the listener presses play.
  static const int _maxAutoRetries = 5;

  // A verse that fails to load is never skipped: the recitation holds on it
  // and retries, so no verse is missed after a network drop.
  final AudioPlayer _player = AudioPlayer();
  List<AudioSource> _sources = const [];
  Uri? _artUri;
  late final Future<void> _artworkReady;

  bool _stopping = false;
  int? _retryIndex;
  Duration _retryPosition = Duration.zero;
  int _retryAttempt = 0;
  Timer? _retryTimer;
  // Set when retries ran out while the listener was still listening, so the
  // recitation picks up again by itself once the network is back.
  bool _resumeOnReconnect = false;
  bool _reloading = false;
  bool _reloadAgain = false;

  /// True while a verse that failed to load is being retried.
  final ValueNotifier<bool> reconnecting = ValueNotifier(false);

  QuranAudioHandler() {
    _player.playbackEventStream.listen(
      (_) => _broadcastState(),
      onError: (Object e, StackTrace st) => log('Recitation error: $e'),
    );
    _player.playingStream.listen((_) => _broadcastState());
    _player.errorStream.listen(_onLoadError);
    Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);

    // Sequence and index arrive together here, so the published item can
    // never belong to a previous queue.
    _player.sequenceStateStream.listen((state) {
      final tag = state.currentSource?.tag;
      // Nothing is forwarded without a queue: a late event after stop()
      // would otherwise re-post the notification that stop() removed.
      if (_stopping || _sources.isEmpty || tag is! MediaItem) return;
      // Only publish a real change: every update makes the platform refresh
      // the notification.
      final current = mediaItem.value;
      if (current?.id == tag.id &&
          current?.extras?['index'] == tag.extras?['index']) {
        return;
      }
      mediaItem.add(tag);
    });

    // Duration lets the notification and lock screen draw a seek bar.
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (_stopping || _sources.isEmpty) return;
      if (current != null && duration != null && current.duration != duration) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });

    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.ready && _retryIndex != null) {
        _clearRetry();
      } else if (state == ProcessingState.completed) {
        stop();
      }
    });

    _configureSession();
    _artworkReady = _prepareArtwork();
  }

  Stream<Duration> get positionStream => _player.positionStream;

  Future<void> _configureSession() async {
    try {
      final session = await AudioSession.instance;
      // Spoken-word profile: pauses (rather than ducks) when another app
      // briefly needs audio, so no words of the recitation are missed.
      await session.configure(const AudioSessionConfiguration.speech());
    } catch (e) {
      log('Audio session configuration failed: $e');
    }
  }

  // The media session needs artwork as a URI. On Android it is served by
  // RecitationArtworkProvider, because the notification and lock screen run
  // in another process that cannot read the app's private files. Elsewhere
  // the bundled logo is copied to a file once.
  Future<void> _prepareArtwork() async {
    try {
      if (Platform.isAndroid) {
        final packageName = (await PackageInfo.fromPlatform()).packageName;
        _artUri = Uri.parse(
            'content://$packageName.recitationartwork/recitation_artwork.png');
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/recitation_artwork.png');
      if (!await file.exists()) {
        final data = await rootBundle.load(_artworkAsset);
        await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }
      _artUri = file.uri;
    } catch (e) {
      log('Recitation artwork unavailable: $e');
    }
  }

  Future<void> playTracks(
    List<RecitationTrack> tracks, {
    int startIndex = 0,
    required String Function(int surahId) surahTitle,
  }) async {
    if (tracks.isEmpty) return;
    await _artworkReady;
    final items = _mediaItemsFor(tracks, surahTitle);

    _clearRetry();
    _sources = [
      for (var i = 0; i < tracks.length; i++)
        AudioSource.uri(Uri.parse(tracks[i].url), tag: items[i]),
    ];
    queue.add(items);
    mediaItem.add(items[startIndex.clamp(0, items.length - 1)]);
    try {
      // Replaces any queue already playing without passing through idle,
      // which the platform would treat as stopped.
      await _player.setAudioSources(
        _sources,
        initialIndex: startIndex.clamp(0, tracks.length - 1),
        preload: false,
      );
      // Not awaited: play() completes only when playback pauses or ends.
      _player.play();
    } on PlayerInterruptedException {
      // A newer playTracks call replaced this one.
    } catch (e) {
      log('Recitation failed to start: $e');
      await stop();
    }
  }

  List<MediaItem> _mediaItemsFor(
      List<RecitationTrack> tracks, String Function(int) surahTitle) {
    return [
      for (var i = 0; i < tracks.length; i++)
        MediaItem(
          id: tracks[i].url,
          title: tracks[i].isBismillah
              ? 'Bismillah'
              : '${surahTitle(tracks[i].surahId)} · Ayah ${tracks[i].ayahLabel}',
          album: surahTitle(tracks[i].surahId),
          artist: RecitationPlaylist.reciterName,
          artUri: _artUri,
          extras: {
            'index': i,
            'surahId': tracks[i].surahId,
            'ayahNumber': tracks[i].ayahNumber,
            'ayahLabel': tracks[i].ayahLabel,
            'ayatIds': tracks[i].ayatIds,
          },
        ),
    ];
  }

  void _onLoadError(PlayerException error) {
    // A failure can be reported both as an event and as a thrown exception;
    // count it once.
    if (_sources.isEmpty || (_retryTimer?.isActive ?? false)) return;
    log('Recitation could not load item ${error.index}: ${error.message}');
    // Resume the verse that was playing: the failure may have been the
    // next verse loading ahead.
    _retryIndex ??= _player.currentIndex ?? error.index ?? 0;
    if (_retryAttempt == 0) _retryPosition = _player.position;
    _retryTimer?.cancel();
    if (_retryAttempt >= _maxAutoRetries) {
      // Stop holding the foreground service while offline; the network
      // returning (or play()) picks the verse up again.
      _resumeOnReconnect = _resumeOnReconnect || _player.playing;
      _player.pause();
      return;
    }
    reconnecting.value = true;
    _retryTimer = Timer(Duration(seconds: 2 << _retryAttempt), _reload);
    _retryAttempt++;
    _broadcastState();
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!online || _retryIndex == null) return;
    if (!_player.playing && !_resumeOnReconnect) return;
    _retryAttempt = 0;
    _retryTimer?.cancel();
    // Give the new connection a moment to come up.
    _retryTimer = Timer(const Duration(seconds: 1), _reload);
  }

  /// Reloads the queue at the verse that failed, from where it stopped.
  Future<void> _reload() async {
    final index = _retryIndex;
    if (index == null || _sources.isEmpty) return;
    _retryTimer?.cancel();
    // One reload at a time; a request arriving meanwhile runs right after.
    if (_reloading) {
      _reloadAgain = true;
      return;
    }
    _reloading = true;
    try {
      // If still playing, this resumes on its own once loaded.
      await _player.setAudioSources(
        _sources,
        initialIndex: index,
        initialPosition: _retryPosition,
        preload: false,
      );
      if (_resumeOnReconnect) {
        _resumeOnReconnect = false;
        _player.play();
      }
    } on PlayerInterruptedException {
      // Cut short by another load; try again so the verse is never left
      // waiting with nothing scheduled.
      _reloadAgain = true;
    } on PlayerException catch (e) {
      _onLoadError(e);
    } catch (e) {
      log('Recitation reload failed: $e');
    } finally {
      _reloading = false;
      if (_reloadAgain) {
        _reloadAgain = false;
        if (_retryIndex != null && !(_retryTimer?.isActive ?? false)) {
          _retryTimer = Timer(const Duration(seconds: 2), _reload);
        }
      }
    }
  }

  /// While a verse is waiting for the network, Next/Previous move the waiting
  /// verse (and its highlight) instead of the stalled player.
  Future<void> _moveWaitingVerse(int index) async {
    if (index < 0 || index >= _sources.length) return;
    _retryIndex = index;
    _retryPosition = Duration.zero;
    _retryAttempt = 0;
    final item = queue.value[index];
    mediaItem.add(item);
    await _reload();
  }

  void _clearRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryIndex = null;
    _retryAttempt = 0;
    _resumeOnReconnect = false;
    reconnecting.value = false;
  }

  void _broadcastState() {
    final playing = _player.playing;
    final index = _player.currentIndex;
    final count = _player.sequence.length;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (playing) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        // Android 13+ only renders custom actions, so close is custom rather
        // than MediaControl.stop.
        MediaControl.custom(
          androidIcon: 'drawable/ic_recitation_close',
          label: 'Close',
          name: closeAction,
        ),
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
        MediaAction.skipToQueueItem,
      },
      androidCompactActionIndices: const [0, 1, 2],
      // A verse waiting to be retried leaves the player idle, but the platform
      // treats idle as stopped and would drop the notification.
      // Idle with a queue loaded only happens while a verse failed to load:
      // keep the session alive rather than report it stopped.
      processingState: _sources.isNotEmpty &&
              !_stopping &&
              _player.processingState == ProcessingState.idle
          // Paused while waiting shows a play button, not a spinner.
          ? (playing
              ? AudioProcessingState.buffering
              : AudioProcessingState.ready)
          : const {
              ProcessingState.idle: AudioProcessingState.idle,
              ProcessingState.loading: AudioProcessingState.loading,
              ProcessingState.buffering: AudioProcessingState.buffering,
              ProcessingState.ready: AudioProcessingState.ready,
              ProcessingState.completed: AudioProcessingState.completed,
            }[_player.processingState]!,
      playing: playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: count == 0 ? null : index,
    ));
  }

  bool get hasNext => _player.hasNext;
  bool get hasPrevious => _player.hasPrevious;

  @override
  Future<void> play() async {
    if (_retryIndex != null) {
      _retryAttempt = 0;
      await _reload();
    }
    await _player.play();
  }

  @override
  Future<void> pause() {
    // A pause by the listener means they no longer want it resumed.
    _resumeOnReconnect = false;
    return _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    final waiting = _retryIndex;
    if (waiting != null) return _moveWaitingVerse(waiting + 1);
    if (_player.hasNext) await _player.seekToNext();
  }

  /// Restarts the current verse if it has been playing for a few seconds,
  /// otherwise goes back one verse, matching common player behaviour.
  @override
  Future<void> skipToPrevious() async {
    final waiting = _retryIndex;
    if (waiting != null) return _moveWaitingVerse(waiting - 1);
    if (_player.position > const Duration(seconds: 3) || !_player.hasPrevious) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= _player.sequence.length) return;
    await _player.seek(Duration.zero, index: index);
  }

  @override
  Future<dynamic> customAction(String name,
      [Map<String, dynamic>? extras]) async {
    if (name == closeAction) await stop();
  }

  @override
  Future<void> onNotificationDeleted() => stop();

  // Swiping the app away keeps an active recitation going, but cleans up a
  // paused one so no idle notification is left behind.
  @override
  Future<void> onTaskRemoved() async {
    if (!_player.playing) await stop();
  }

  @override
  Future<void> stop() async {
    if (_stopping) return;
    _stopping = true;
    try {
      _sources = const [];
      _clearRetry();
      // The platform refreshes the notification shortly after each update.
      // Pausing first and letting any pending refresh land before going idle
      // stops a late refresh from re-posting a stale notification after it
      // has been removed.
      await _player.pause();
      await Future<void>.delayed(const Duration(milliseconds: 300));
      await _player.stop();
      queue.add(const []);
      mediaItem.add(null);
      playbackState.add(playbackState.value.copyWith(
        processingState: AudioProcessingState.idle,
        playing: false,
        queueIndex: null,
      ));
      await super.stop();
    } finally {
      _stopping = false;
    }
  }
}
