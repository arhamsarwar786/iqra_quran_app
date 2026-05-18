import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_share_service.dart';
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
        final config = provider.config;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: AnimatedBuilder(
                animation: _glowAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: isLive
                          ? [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: _glowAnimation.value / 2,
                              )
                            ]
                          : [
                              BoxShadow(
                                color: const Color(0xFF1A4D2E).withOpacity(0.2),
                                blurRadius: _glowAnimation.value,
                                spreadRadius: _glowAnimation.value / 4,
                              )
                            ],
                    ),
                    child: child,
                  );
                },
                child: Card(
                  elevation: 0,
                  color: Colors.transparent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => _handleTap(context, provider),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: isLive
                          ? _buildLiveContent(provider)
                          : _buildCountdownContent(provider),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCountdownContent(HajjLiveProvider provider) {
    final timeService = HajjTimeService();
    final countdownStr = timeService.formatCountdown(provider.remainingTime);
    final themeColor = Provider.of<ThemeProvider>(context).selectedTheme;

    return Container(
      key: const ValueKey("countdown"),
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            themeColor,
            themeColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage("assets/images/BgImage.png"),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              _buildIconBox("🕋", false, themeColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.config?.title ?? "Hajj will be live in",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        countdownStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildShareButton(context, provider),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              _buildSimpleTag("COMING SOON", themeColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.config?.comingSoonMessage ?? "Get ready for the spiritual journey",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLiveContent(HajjLiveProvider provider) {
    return Container(
      key: const ValueKey("live"),
      height: 180,
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [Colors.red.shade700, Colors.red.shade900],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        image: const DecorationImage(
          image: AssetImage("assets/images/BgImage.png"),
          fit: BoxFit.cover,
          opacity: 0.15,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLiveBadge(),
              _buildShareButton(context, provider),
            ],
          ),
          const Spacer(),
          Text(
            provider.config?.title ?? "Watch Hajj Live",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            provider.config?.subtitle ?? "Experience the holy stream from Makkah",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBox(String emoji, bool isLive, Color themeColor) {
    return Container(
      width: 55,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ]
      ),
      child: Center(
        child: isLive 
          ? const Icon(Icons.mosque, color: Colors.red, size: 30)
          : Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fiber_manual_record, color: Colors.red, size: 12),
          SizedBox(width: 6),
          Text(
            "LIVE NOW",
            style: TextStyle(
                color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTag(String text, Color themeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))
        ]
      ),
      child: Text(
        text,
        style: TextStyle(
            color: themeColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, HajjLiveProvider provider) {
    return IconButton(
      icon: const Icon(Icons.share, color: Colors.white70, size: 20),
      onPressed: () {
        HajjShareService.shareHajjCard(
          context: context,
          bloc: Provider.of<ThemeProvider>(context, listen: false),
          provider: provider,
        );
      },
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
          height: 180,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
        ),
      ),
    );
  }
}
