import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:http/http.dart' show ClientException;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../Provider/audio_provider.dart';
import '../Services/verse_video.dart';

typedef ShareImageMaker = Future<File> Function(bool watermark);
typedef ShareVideoMaker = Future<File> Function(
    bool watermark, VideoProgress onProgress);

/// The preview shown before sharing anything: the card as an IMAGE or a
/// VIDEO, always with the light logo watermark.
class SharePreview extends StatefulWidget {
  static const String shareText =
      'Download IQRA QURAN: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';

  final Color theme;
  final ShareImageMaker makeImage;

  /// Null where video sharing is not available.
  final ShareVideoMaker? makeVideo;

  /// One line telling the user what the video will contain.
  final String videoDescription;

  /// Message sent along with the shared file.
  final String text;

  const SharePreview({
    super.key,
    required this.theme,
    required this.makeImage,
    this.makeVideo,
    this.videoDescription = '',
    this.text = shareText,
  });

  static Future<void> show(
    BuildContext context, {
    required Color theme,
    required ShareImageMaker makeImage,
    ShareVideoMaker? makeVideo,
    String videoDescription = '',
    String text = shareText,
  }) {
    return showDialog(
      context: context,
      useSafeArea: true,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (context) => SharePreview(
        theme: theme,
        makeImage: makeImage,
        makeVideo: VerseVideo.isSupported ? makeVideo : null,
        videoDescription: videoDescription,
        text: text,
      ),
    );
  }

  @override
  State<SharePreview> createState() => _SharePreviewState();
}

enum _Format { image, video }

class _SharePreviewState extends State<SharePreview> {
  // The format chosen last time, so the preview opens on it again.
  static _Format _lastFormat = _Format.image;

  _Format _format = _Format.image;

  File? _image;
  File? _video;
  bool _imageLoading = false;
  String? _imageError;

  bool _making = false;
  String _stage = '';
  double _progress = 0;
  String? _videoError;
  VideoPlayerController? _player;
  File? _playerFile;
  bool _saving = false;

  // The dialog's own messenger, so its messages show above the barrier.
  final _messenger = GlobalKey<ScaffoldMessengerState>();

  Color get _theme => widget.theme;

  @override
  void initState() {
    super.initState();
    _ensureImage();
    if (widget.makeVideo != null && _lastFormat == _Format.video) {
      _format = _Format.video;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _ensureVideo();
      });
    }
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _ensureImage() async {
    if (_image != null || _imageLoading) return;
    setState(() {
      _imageLoading = true;
      _imageError = null;
    });
    try {
      final file = await widget.makeImage(true);
      if (mounted) setState(() => _image = file);
    } catch (e) {
      if (mounted) {
        setState(() => _imageError = 'The image could not be created.');
      }
    } finally {
      if (mounted) setState(() => _imageLoading = false);
    }
  }

  Future<void> _ensureVideo() async {
    final existing = _video;
    if (existing != null) return _showVideo(existing);
    if (_making) return;
    setState(() {
      _making = true;
      _videoError = null;
      _stage = 'Starting…';
      _progress = 0;
    });
    try {
      final file = await widget.makeVideo!(true, (stage, progress) {
        if (mounted) {
          setState(() {
            _stage = stage;
            _progress = progress;
          });
        }
      });
      _video = file;
    } on SocketException {
      _failOffline();
    } on ClientException {
      _failOffline();
    } on TimeoutException {
      _failOffline();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _videoError = 'The video could not be created. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _making = false);
    }
    if (mounted && _format == _Format.video && _videoError == null) {
      _ensureVideo();
    }
  }

  void _failOffline() {
    if (!mounted) return;
    setState(() => _videoError = 'The video needs an internet connection to '
        'download the recitation. Please connect and try again, or download '
        'this surah to make videos offline.');
  }

  Future<void> _showVideo(File file) async {
    if (_playerFile == file) {
      if (_format == _Format.video) _play();
      return;
    }
    final old = _player;
    final player = VideoPlayerController.file(file);
    await player.initialize();
    // Plays once and stops at the end.
    await player.setLooping(false);
    if (!mounted) {
      player.dispose();
      return;
    }
    setState(() {
      _player = player;
      _playerFile = file;
    });
    old?.dispose();
    if (_format == _Format.video) _play();
  }

  // The video has its own sound, so pause any recitation already playing.
  void _play() {
    final player = _player;
    if (player == null) return;
    final recitation = context.read<AudioProvider>();
    if (recitation.isPlaying) recitation.pausePlayback();
    // Play again from the start once it has finished.
    final value = player.value;
    if (value.duration > Duration.zero && value.position >= value.duration) {
      player.seekTo(Duration.zero);
    }
    player.play();
  }

  void _togglePlay() {
    final player = _player;
    if (player == null) return;
    setState(() => player.value.isPlaying ? player.pause() : _play());
  }

  void _selectFormat(_Format format) {
    _lastFormat = format;
    setState(() => _format = format);
    if (format == _Format.video) {
      _ensureVideo();
    } else {
      _player?.pause();
    }
  }

  File? get _shareable => _format == _Format.image ? _image : _video;

  // The preview stays open on the chosen format while the share sheet shows.
  void _share() {
    final file = _shareable;
    if (file == null) return;
    _player?.pause();
    Share.shareXFiles([
      _format == _Format.image
          ? XFile(file.path)
          : XFile(file.path, mimeType: 'video/mp4'),
    ], text: widget.text);
  }

  Future<void> _download() async {
    final file = _shareable;
    if (file == null) return;
    final isVideo = _format == _Format.video;
    void tell(String message) =>
        _messenger.currentState?.showSnackBar(SnackBar(content: Text(message)));
    setState(() => _saving = true);
    try {
      if (!await Gal.hasAccess(toAlbum: true) &&
          !await Gal.requestAccess(toAlbum: true)) {
        tell('Allow access to Photos to save to your gallery.');
        return;
      }
      if (isVideo) {
        await Gal.putVideo(file.path, album: 'IQRA QURAN');
      } else {
        await Gal.putImage(file.path, album: 'IQRA QURAN');
      }
      tell(isVideo ? 'Video saved to gallery' : 'Image saved to gallery');
    } catch (e) {
      tell(isVideo
          ? 'The video could not be saved.'
          : 'The image could not be saved.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _messenger,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed:
                              _shareable != null && !_saving ? _download : null,
                          tooltip: 'Download',
                          color: Colors.white,
                          disabledColor: Colors.white38,
                          icon: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.download_rounded),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton.icon(
                          onPressed: _shareable != null ? _share : null,
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Share Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _theme,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.white24,
                            disabledForegroundColor: Colors.white54,
                            shape: const StadiumBorder(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (widget.makeVideo != null) _formatSwitch(),
              Expanded(
                child: _format == _Format.image ? _imageBody() : _videoBody(),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formatSwitch() {
    Widget option(_Format format, IconData icon, String label) {
      final selected = _format == format;
      return Expanded(
        child: GestureDetector(
          onTap: () => _selectFormat(format),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: selected ? _theme : Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _theme : Colors.white,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white38),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          option(_Format.image, Icons.image_rounded, 'IMAGE'),
          option(_Format.video, Icons.videocam_rounded, 'VIDEO'),
        ],
      ),
    );
  }

  Widget _imageBody() {
    final image = _image;
    if (image == null) {
      return Center(
        child: _imageError != null
            ? Text(_imageError!, style: const TextStyle(color: Colors.white))
            : const CircularProgressIndicator(color: Colors.white),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(image),
      ),
    );
  }

  Widget _videoBody() {
    final player = _player;
    if (_video != null &&
        player != null &&
        _playerFile == _video &&
        player.value.isInitialized) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: GestureDetector(
            onTap: _togglePlay,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: player.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(player),
                    // Play/pause stays visible, a little faded while playing.
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: player,
                      builder: (context, value, _) => AnimatedOpacity(
                        opacity: value.isPlaying ? 0.6 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                              value.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 44),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: VideoProgressIndicator(
                        player,
                        allowScrubbing: true,
                        padding: const EdgeInsets.only(top: 12),
                        colors: VideoProgressColors(
                          playedColor: _theme,
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final error = _videoError;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                error == null
                    ? Icons.movie_creation_rounded
                    : Icons.error_outline_rounded,
                color: Colors.white70,
                size: 48),
            const SizedBox(height: 18),
            Text(
              error ?? _stage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 18),
            if (error == null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              const SizedBox(height: 10),
              Text('${(_progress * 100).round()}%',
                  style: const TextStyle(color: Colors.white70)),
              if (widget.videoDescription.isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(
                  widget.videoDescription,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white54, fontSize: 12.5),
                ),
              ],
            ] else
              ElevatedButton.icon(
                onPressed: _ensureVideo,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _theme,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
