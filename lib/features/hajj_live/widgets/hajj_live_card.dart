import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_time_service.dart';
import 'package:iqra/Provider/theme_provider.dart';
import '../models/hajj_stream_model.dart';
import '../screens/hajj_live_screen.dart';
import '../screens/hajj_coming_soon_screen.dart';
import 'package:shimmer/shimmer.dart';

class HajjLiveCard extends StatefulWidget {
  const HajjLiveCard({Key? key}) : super(key: key);

  @override
  State<HajjLiveCard> createState() => _HajjLiveCardState();
}

class _HajjLiveCardState extends State<HajjLiveCard>
    with SingleTickerProviderStateMixin {
  // share key removed
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 2.0, end: 10.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HajjLiveProvider>(
      builder: (context, provider, child) {
        if (provider.status == HajjLiveStatus.loading &&
            provider.config == null) {
          return _buildLoadingCard();
        }

        final isLive = provider.isLive;
        final themeColor = Provider.of<ThemeProvider>(context).selectedTheme;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(isLive ? 0.35 : 0.2),
                      blurRadius: _glowAnimation.value * (isLive ? 1.3 : 1.0),
                      spreadRadius: _glowAnimation.value / (isLive ? 2.5 : 4.0),
                    )
                  ],
                ),
                child: child,
              );
            },
            child: Material(
              borderRadius: BorderRadius.circular(24),
              elevation: 4,
              shadowColor: themeColor.withOpacity(0.3),
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _handleTap(context, provider),
                child: _buildHajjCardContent(provider,
                    isLive: isLive, themeColor: themeColor),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHajjCardContent(HajjLiveProvider provider,
      {required bool isLive, required Color themeColor}) {
    final timeService = HajjTimeService();
    final countdownStr = timeService.formatCountdown(provider.remainingTime);

    final title = provider.config?.title ??
        (isLive ? "Watch Hajj Live" : "Hajj will be live in");
    final subtitle = isLive
        ? (provider.config?.subtitle ??
            "Experience the holy stream from Makkah")
        : countdownStr;

    final comingSoonMsg = provider.config?.comingSoonMessage ?? "COMING SOON";

    final gradientStart = themeColor;
    final gradientEnd = themeColor.withOpacity(0.75);

    return Container(
      key: ValueKey(isLive ? "live" : "countdown"),
      height: 95, // slightly taller to accommodate top badges
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Decorative Arabic text watermark (Hajj)
          Positioned(
            right: 16,
            top: 0,
            bottom: 0,
            child: Center(
              child: Text(
                "حج",
                style: TextStyle(
                  fontSize: 42,
                  color: Colors.white.withOpacity(0.12),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Decorative circle
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.07),
              ),
            ),
          ),
          // NEW Badge (Top Left)
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: const BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: const Text(
                "NEW",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // Coming Soon / Live Badge (Top Right)
          Positioned(
            right: 16,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isLive ? Colors.black.withOpacity(0.35) : Colors.red.shade700,
                borderRadius: BorderRadius.circular(6),
                border: isLive
                    ? Border.all(color: Colors.white.withOpacity(0.15), width: 0.8)
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLive) ...[
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Transform.scale(
                          scale: 1.0 + (_glowController.value * 0.5),
                          child: Opacity(
                            opacity: 1.0 - _glowController.value,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 6),
                  ] else ...[
                    const Icon(Icons.fiber_manual_record,
                        color: Colors.white, size: 8),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    isLive ? "LIVE NOW" : "COMING SOON",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          Padding(
            padding:
                const EdgeInsets.only(left: 20, right: 20, top: 22, bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Image.asset(
                      'assets/images/kaaba.png',
                      width: 32,
                      height: 32,
                      fit: BoxFit.contain,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(isLive ? 0.75 : 0.9),
                          fontSize: isLive ? 11 : 13,
                          fontWeight:
                              isLive ? FontWeight.w500 : FontWeight.w700,
                          letterSpacing: isLive ? 0 : 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(BuildContext context, HajjLiveProvider provider) {
    if (provider.isLive) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                HajjLiveScreen(streamId: provider.config?.streamId ?? "")),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => HajjComingSoonScreen(config: provider.config!)),
      );
    }
  }

  Widget _buildLoadingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}
