import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/features/hajj_live/widgets/hajj_player.dart';
import 'package:provider/provider.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_share_service.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'hajj_stream_error_screen.dart';
import 'package:shimmer/shimmer.dart';

enum StreamPlaybackState {
  idle,
  loading,
  buffering,
  live,
  reconnecting,
  failed,
  offline
}

class HajjLiveScreen extends StatefulWidget {
  final String streamId;

  const HajjLiveScreen({Key? key, required this.streamId}) : super(key: key);

  @override
  State<HajjLiveScreen> createState() => _HajjLiveScreenState();
}

class _HajjLiveScreenState extends State<HajjLiveScreen> {
  StreamPlaybackState _playbackState = StreamPlaybackState.loading;
  int _playerRetryKey = 0;
  // share key removed

  @override
  void initState() {
    super.initState();
    // In a real app, this state would be driven by the player controller
    // For now, we simulate the transition from loading to live
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _playbackState = StreamPlaybackState.live);
      }
    });
  }

  @override
  void dispose() {
    // Restore portrait orientation and show system UI when leaving the screen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HajjLiveProvider>(
      builder: (context, provider, child) {
        final config = provider.config;
        if (config == null) return const HajjStreamErrorScreen(streamId: "");

        return Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: [
              // The Video Player
              Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: HajjPlayer(
                    key: ValueKey("hajj_player_$_playerRetryKey"),
                    streamUrl: config.streamUrl,
                    streamId: config.streamId.isNotEmpty ? config.streamId : widget.streamId,
                    platform: config.streamPlatform,
                    onStateChanged: (state) {
                      if (mounted) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() => _playbackState = state);
                          }
                        });
                      }
                    },
                  ),
                ),
              ),

              // Overlay UI
              _buildTopBar(context, provider),
              _buildBottomStatus(),

              // Loading/Buffering/Error Overlays
              if (_playbackState == StreamPlaybackState.loading)
                _buildLoadingOverlay(),
              if (_playbackState == StreamPlaybackState.buffering)
                _buildBufferingIndicator(),
              if (_playbackState == StreamPlaybackState.reconnecting)
                _buildReconnectingOverlay(),
              if (_playbackState == StreamPlaybackState.failed)
                _buildFailedOverlay(context, provider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, HajjLiveProvider provider) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 10,
          left: 16,
          right: 16,
          bottom: 20,
        ),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Column(
              children: [
                const Text(
                  "Hajj Live Stream",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Poppins'),
                ),
                if (_playbackState == StreamPlaybackState.live)
                  _buildAnimatedLiveTag(),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.share, color: Colors.white),
              onPressed: () {
                HajjShareService.shareHajjCard(
                  context: context,
                  bloc: Provider.of<ThemeProvider>(context, listen: false),
                  provider: provider,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedLiveTag() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.fiber_manual_record, color: Colors.red, size: 10),
        const SizedBox(width: 4),
        Shimmer.fromColors(
          baseColor: Colors.red,
          highlightColor: Colors.white,
          child: const Text(
            "LIVE NOW",
            style: TextStyle(
                color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomStatus() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fullscreen Landscape Button
          GestureDetector(
            onTap: () async {
              await SystemChrome.setPreferredOrientations([
                DeviceOrientation.landscapeLeft,
                DeviceOrientation.landscapeRight,
              ]);
              await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "Full Screen",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Consumer<HajjLiveProvider>(
            builder: (context, provider, child) {
              return ElevatedButton.icon(
                onPressed: () {
                  HajjShareService.shareHajjCard(
                    context: context,
                    bloc: Provider.of<ThemeProvider>(context, listen: false),
                    provider: provider,
                  );
                },
                icon: const Icon(Icons.share, color: Colors.white),
                label: const Text("Share Live Stream",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Provider.of<ThemeProvider>(context).selectedTheme,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _playbackState == StreamPlaybackState.live
                  ? "Connected to holy stream"
                  : "Optimizing playback...",
              style:
                  TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Shimmer.fromColors(
              baseColor: Colors.white10,
              highlightColor: Colors.white24,
              child: Container(
                width: 200,
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2),
            const SizedBox(height: 24),
            const Text(
              "Connecting to Hajj live stream...",
              style: TextStyle(color: Colors.white70, fontFamily: 'Poppins'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return const Center(
        child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2));
  }

  Widget _buildReconnectingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sync, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            const Text("Connection lost. Reconnecting...",
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildFailedOverlay(BuildContext context, HajjLiveProvider provider) {
    return Container(
      color: Colors.black87,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              const Text(
                "Playback failed",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "The connection to the stream was lost.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _playbackState = StreamPlaybackState.loading;
                    _playerRetryKey++; // Forces HajjPlayer to recreate state
                  });
                  try {
                    await provider.refreshConfig();
                  } catch (e) {
                    debugPrint("Retry refresh config error: $e");
                  }
                },
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "RETRY CONNECTION",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Provider.of<ThemeProvider>(context, listen: false).selectedTheme,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
