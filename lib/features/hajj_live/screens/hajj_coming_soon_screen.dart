import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_share_service.dart';
import '../services/hajj_time_service.dart';
import 'package:iqra/Provider/theme_provider.dart';

class HajjComingSoonScreen extends StatefulWidget {
  const HajjComingSoonScreen({Key? key, required config}) : super(key: key);

  @override
  State<HajjComingSoonScreen> createState() => _HajjComingSoonScreenState();
}

class _HajjComingSoonScreenState extends State<HajjComingSoonScreen> {
  // share key removed
  late VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/hajj-video.mp4')
          ..initialize().then((_) {
            _videoController.setVolume(0.0);
            _videoController
                .setPlaybackSpeed(0.5); // Slow down for premium feel
            _videoController.setLooping(true);
            _videoController.play();
            setState(() {});
          });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HajjLiveProvider>(
      builder: (context, provider, child) {
        final timeService = HajjTimeService();
        final countdownStr =
            timeService.formatCountdown(provider.remainingTime);

        return Scaffold(
          backgroundColor: Colors.black, // Dark background base
          body: Stack(
            children: [
              // Background Video
              if (_videoController.value.isInitialized)
                SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              else
                Container(
                    color: const Color(
                        0xFF0E323F)), // Fallback color while loading

              // Premium Gradient Overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0E323F).withOpacity(0.4),
                      const Color(0xFF0E323F).withOpacity(0.95),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, provider),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 30.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 40),
                            _buildHeroSection(provider),
                            const SizedBox(height: 60),
                            _buildCountdownSection(countdownStr),
                            const SizedBox(height: 60),
                            _buildDetailsCard(provider),
                            const SizedBox(height: 60),
                            _buildBottomActions(context, provider),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context, HajjLiveProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Text(
            "PREPARING LIVE",
            style: TextStyle(
                color: Colors.white54,
                fontWeight: FontWeight.bold,
                letterSpacing: 2),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white),
            onPressed: () => _handleShare(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(HajjLiveProvider provider) {
    return Column(
      children: [
        // Premium Kaaba Image with glow
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.4),
                blurRadius: 30,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Image.asset(
            'assets/images/kaaba.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 24),
        // Main Title
        const Text(
          "Hajj Live 2026",
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        const SizedBox(height: 6),
        // Date badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: const Text(
            "26 May 2026",
            style: TextStyle(
                color: Colors.amber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "The journey of a lifetime",
          style: TextStyle(
              color: Colors.white54, fontSize: 16, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(String countdown) {
    return Column(
      children: [
        const Text(
          "OFFICIAL START IN",
          style: TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
              fontSize: 12),
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  countdown,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsCard(HajjLiveProvider provider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  SizedBox(width: 10),
                  Text("Stream Information",
                      style: TextStyle(
                          color: Colors.amber, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                provider.config?.description ??
                    "Join millions of Muslims in performing the holy pilgrimage of Hajj. We will bring you the live stream from Makkah Mukarramah.",
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context, HajjLiveProvider provider) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () => _handleShare(provider),
          icon: const Icon(Icons.ios_share),
          label: const Text("SHARE COUNTDOWN",
              style: TextStyle(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0E323F),
            minimumSize: const Size(double.infinity, 60),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () => provider.refreshConfig(),
          child: const Text("Check Stream Status Now",
              style: TextStyle(color: Colors.amber)),
        ),
      ],
    );
  }

  void _handleShare(HajjLiveProvider provider) {
    HajjShareService.shareHajjCard(
      context: context,
      bloc: Provider.of<ThemeProvider>(context, listen: false),
      provider: provider,
    );
  }
}
