import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_share_service.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Models/tasbeeh_model.dart';
import 'package:iqra/Provider/tasbih_count.dart';

class HajjComingSoonScreen extends StatefulWidget {
  const HajjComingSoonScreen({Key? key, required config}) : super(key: key);

  @override
  State<HajjComingSoonScreen> createState() => _HajjComingSoonScreenState();
}

class _HajjComingSoonScreenState extends State<HajjComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  final PageController _pageController = PageController(viewportFraction: 0.88);
  Map<String, dynamic>? _hajjData;
  int _currentSlide = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _videoController =
        VideoPlayerController.asset('assets/videos/hajj-video.mp4')
          ..initialize().then((_) {
            _videoController.setVolume(0.0);
            _videoController.setPlaybackSpeed(0.5);
            _videoController.setLooping(true);
            _videoController.play();
            setState(() {});
          });

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut);
    _fadeController.forward();

    _loadHajjData();
  }

  Future<void> _loadHajjData() async {
    try {
      final String jsonStr =
          await rootBundle.loadString('assets/json_data/hajj.json');
      setState(() {
        _hajjData = jsonDecode(jsonStr);
      });
    } catch (e) {
      debugPrint('Error loading hajj data: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<HajjLiveProvider>(
      builder: (context, provider, child) {
        final theme = Provider.of<ThemeProvider>(context).selectedTheme;
        final remainingTime = provider.remainingTime;
        final days = remainingTime.inDays;
        final hours = remainingTime.inHours.remainder(24);
        final minutes = remainingTime.inMinutes.remainder(60);
        final seconds = remainingTime.inSeconds.remainder(60);

        return Scaffold(
          backgroundColor: Colors.black,
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
                Container(color: const Color(0xFF0A1F25)),

              // Dark gradient overlay
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xCC0A1F25),
                      Color(0xF00A1F25),
                    ],
                  ),
                ),
              ),

              SafeArea(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildAppBar(context, provider),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              const SizedBox(height: 16),
                              _buildHeroSection(),
                              const SizedBox(height: 28),
                              _buildCountdownSection(
                                  days, hours, minutes, seconds),
                              const SizedBox(height: 32),
                              // Arabic Ayat Slider (Clickable)
                              _buildAyatSlider(theme),
                              const SizedBox(height: 28),
                              // Hajj Duas & Dhikr List
                              _buildHajjDhikrList(theme),
                              const SizedBox(height: 30),
                              _buildBottomActions(context, provider),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              "HAJJ 1447 AH",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => HajjShareService.shareHajjCard(
              context: context,
              bloc: Provider.of<ThemeProvider>(context, listen: false),
              provider: Provider.of<HajjLiveProvider>(context, listen: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        // Glowing Kaaba image
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.07),
            border: Border.all(color: Colors.amber.withOpacity(0.35), width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset('assets/images/kaaba.png', fit: BoxFit.contain),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Hajj Live 2026",
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.amber.withOpacity(0.45)),
          ),
          child: const Text(
            "26 May 2026  •  9 Dhul-Hijjah 1447",
            style: TextStyle(
              color: Colors.amber,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "The journey of a lifetime",
          style: TextStyle(
              color: Colors.white54, fontSize: 14, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(int days, int hours, int minutes, int seconds) {
    return Column(
      children: [
        const Text(
          "STARTS IN",
          style: TextStyle(
            color: Colors.amber,
            fontWeight: FontWeight.bold,
            letterSpacing: 4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCountUnit(days.toString().padLeft(2, '0'), 'DAYS'),
            _buildSep(),
            _buildCountUnit(hours.toString().padLeft(2, '0'), 'HRS'),
            _buildSep(),
            _buildCountUnit(minutes.toString().padLeft(2, '0'), 'MIN'),
            _buildSep(),
            _buildCountUnit(seconds.toString().padLeft(2, '0'), 'SEC'),
          ],
        ),
      ],
    );
  }

  Widget _buildCountUnit(String value, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 68,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.12)),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  height: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSep() => const Padding(
        padding: EdgeInsets.only(bottom: 16, left: 4, right: 4),
        child: Text(":",
            style: TextStyle(
                color: Colors.amber,
                fontSize: 26,
                fontWeight: FontWeight.bold)),
      );

  // ─── ARABIC AYAT SLIDER ─────────────────────────────────────────────────
  Widget _buildAyatSlider(Color theme) {
    final ayat = _hajjData?['quran_ayat'] as List? ?? [];
    final talbiyah = _hajjData?['talbiyah'];

    // Combine talbiyah + ayat into a unified list of cards
    final List<Map<String, dynamic>> cards = [];
    if (talbiyah != null) {
      cards.add({
        'type': 'talbiyah',
        'label': 'TALBIYAH',
        'surah': talbiyah['occasion'] ?? 'Recite in Ihram',
        'arabic': talbiyah['arabic'],
        'transliteration': talbiyah['transliteration'],
        'translation': talbiyah['translation'],
      });
    }
    for (final a in ayat) {
      cards.add({
        'type': 'ayah',
        'label': 'QURAN',
        'surah': '${a['surah']} ${a['ayah_number']}',
        'arabic': a['arabic'],
        'transliteration': a['transliteration'],
        'translation': a['translation'],
      });
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(Icons.auto_stories_rounded, color: Colors.amber, size: 18),
              SizedBox(width: 8),
              Text(
                "Duas & Ayat of Hajj (Read Arabic)",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _pageController,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _currentSlide = i),
            itemBuilder: (context, index) {
              final card = cards[index];
              final bool isTalbiyah = card['type'] == 'talbiyah';
              return AnimatedScale(
                scale: _currentSlide == index ? 1.0 : 0.94,
                duration: const Duration(milliseconds: 300),
                child: _buildAyatCard(card, isTalbiyah, theme),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cards.length, (i) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentSlide == i ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentSlide == i ? Colors.amber : Colors.white24,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAyatCard(Map<String, dynamic> card, bool isTalbiyah, Color theme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openTasbeeh(
          card['arabic'] ?? '',
          card['transliteration'] ?? '',
          card['translation'] ?? '',
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isTalbiyah
                  ? [const Color(0xFF1A3A2A), const Color(0xFF0D2218)]
                  : [const Color(0xFF1A2A3A), const Color(0xFF0D1A25)],
            ),
            border: Border.all(
              color: isTalbiyah
                  ? Colors.green.withOpacity(0.35)
                  : Colors.amber.withOpacity(0.25),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: (isTalbiyah ? Colors.green : Colors.amber).withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Arabic watermark
              Positioned(
                right: 10,
                bottom: 10,
                child: Text(
                  "حج",
                  style: TextStyle(
                    fontSize: 80,
                    color: Colors.white.withOpacity(0.04),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + Tap hint row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (isTalbiyah ? Colors.green : Colors.amber).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (isTalbiyah ? Colors.green : Colors.amber).withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            card['label'],
                            style: TextStyle(
                              color: isTalbiyah ? Colors.green.shade300 : Colors.amber,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.touch_app, color: Colors.white70, size: 10),
                              SizedBox(width: 4),
                              Text("TAP TO TASBEEH", style: TextStyle(color: Colors.white70, fontSize: 8)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Arabic text centered
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            card['arabic'],
                            textAlign: TextAlign.center,
                            textDirection: TextDirection.rtl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                              fontFamily: 'AlQalamQuranMajeed',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HAJJ DHIKR LIST ────────────────────────────────────────────────────
  Widget _buildHajjDhikrList(Color theme) {
    final talbiyah = _hajjData?['talbiyah'];
    final takbeerat = _hajjData?['takbeerat'] as List? ?? [];
    final dhikr = _hajjData?['recommended_dhikr'] as List? ?? [];

    final List<Map<String, dynamic>> items = [];
    if (talbiyah != null) {
      items.add({
        'title': 'Talbiyah',
        'arabic': talbiyah['arabic'],
        'transliteration': talbiyah['transliteration'],
        'translation': talbiyah['translation'],
      });
    }
    if (takbeerat.isNotEmpty) {
      items.add({
        'title': 'Takbeer for Hajj and Eid',
        'arabic': takbeerat[0]['arabic'],
        'transliteration': takbeerat[0]['transliteration'],
        'translation': takbeerat[0]['translation'],
      });
    }
    for (final d in dhikr) {
      items.add({
        'title': d['name'] ?? 'Dhikr',
        'arabic': d['arabic'] ?? d['phrase'],
        'transliteration': d['transliteration'] ?? d['phrase'],
        'translation': d['meaning'],
      });
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            "Hajj Duas & Dhikr",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => _buildDhikrCard(item, theme)).toList(),
      ],
    );
  }

  Widget _buildDhikrCard(Map<String, dynamic> item, Color theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openTasbeeh(
            item['arabic'] ?? '',
            item['transliteration'] ?? '',
            item['translation'] ?? '',
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.touch_app_rounded, color: theme, size: 22),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'],
                        style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['arabic'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['translation'],
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white38, size: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openTasbeeh(String arabic, String transliteration, String translation) {
    context.read<TasbeeCount>().setValue(0);
    var t = TasbeehModel(
      arabic: arabic,
      transliteration: transliteration,
      urduMeaning: translation,
    );
    context.read<TasbeehProvider>().setSelectedTasbeeh(t);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const Tasbih()));
  }

  Widget _buildBottomActions(BuildContext context, HajjLiveProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: () => HajjShareService.shareHajjCard(
              context: context,
              bloc: Provider.of<ThemeProvider>(context, listen: false),
              provider: provider,
            ),
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text("SHARE COUNTDOWN",
                style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0A1F25),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 14),
          TextButton(
            onPressed: () => provider.refreshConfig(),
            child: const Text("Check Stream Status",
                style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }
}
