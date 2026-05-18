import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import '../screens/hajj_live_screen.dart';

class HajjPlayer extends StatefulWidget {
  final String streamUrl;
  final String streamId;
  final String platform;
  final Function(StreamPlaybackState)? onStateChanged;

  const HajjPlayer({
    Key? key,
    required this.streamUrl,
    required this.streamId,
    required this.platform,
    this.onStateChanged,
  }) : super(key: key);

  @override
  State<HajjPlayer> createState() => _HajjPlayerState();
}

class _HajjPlayerState extends State<HajjPlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  bool _isHls = false;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _isHls = widget.streamUrl.toLowerCase().endsWith('.m3u8') || widget.platform == 'hls';
    if (_isHls) {
      _initializeHlsPlayer();
    } else {
      widget.onStateChanged?.call(StreamPlaybackState.live);
    }
  }

  Future<void> _initializeHlsPlayer() async {
    widget.onStateChanged?.call(StreamPlaybackState.loading);
    
    _videoPlayerController = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl));
    
    try {
      await _videoPlayerController!.initialize();
      _videoPlayerController!.addListener(_videoListener);
      
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        isLive: true,
        aspectRatio: _videoPlayerController!.value.aspectRatio,
        allowFullScreen: true,
        showControls: true,
        placeholder: Container(color: Colors.black),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 42),
                const SizedBox(height: 16),
                const Text("Playback Error", style: TextStyle(color: Colors.white)),
                TextButton(
                  onPressed: _initializeHlsPlayer,
                  child: const Text("Retry", style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
          );
        },
      );
      
      if (mounted) {
        setState(() {});
        widget.onStateChanged?.call(StreamPlaybackState.live);
      }
    } catch (e) {
      debugPrint("HLS Init Error: $e");
      _handleError();
    }
  }

  void _videoListener() {
    if (_videoPlayerController == null) return;

    if (_videoPlayerController!.value.isBuffering) {
      widget.onStateChanged?.call(StreamPlaybackState.buffering);
    } else if (_videoPlayerController!.value.hasError) {
      _handleError();
    } else {
      widget.onStateChanged?.call(StreamPlaybackState.live);
    }
  }

  void _handleError() {
    if (_retryCount < 5) {
      _retryCount++;
      widget.onStateChanged?.call(StreamPlaybackState.reconnecting);
      Future.delayed(const Duration(seconds: 5), _initializeHlsPlayer);
    } else {
      widget.onStateChanged?.call(StreamPlaybackState.failed);
    }
  }

  @override
  void dispose() {
    _videoPlayerController?.removeListener(_videoListener);
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isHls) {
      if (_chewieController != null && _chewieController!.videoPlayerController.value.isInitialized) {
        return Chewie(controller: _chewieController!);
      } else {
        return Container(color: Colors.black);
      }
    } else {
      // YouTube Fallback
      final String embedUrl = "https://www.youtube.com/embed/${widget.streamId}?autoplay=1&mute=0&rel=0&playsinline=1";
      return InAppWebView(
        initialUrlRequest: URLRequest(url: WebUri(embedUrl)),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          mediaPlaybackRequiresUserGesture: false,
          allowsInlineMediaPlayback: true,
        ),
      );
    }
  }
}
