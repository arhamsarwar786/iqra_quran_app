// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Screens/MainPage/main_screen.dart';
import 'package:iqra/Screens/Permission/permission_screen.dart';
import 'package:iqra/Services/analytics_service.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo breathing animation ──────────────────────────────────
  late AnimationController _breathController;
  late Animation<double> _breathScale;

  // ── Shimmer sweep on progress bar ────────────────────────────
  late AnimationController _shimmerController;

  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('app_started');

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xff0E323F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    // Logo breathing
    _breathController = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);
    _breathScale = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // Start initialization in provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qProvider = Provider.of<QuranDataProvider>(context, listen: false);
      qProvider.appInitialize();
      qProvider.addListener(_checkNavigation);
    });
  }

  void _checkNavigation() async {
    final qProvider = Provider.of<QuranDataProvider>(context, listen: false);
    if (qProvider.isLoaded && !_navigated) {
      _navigated = true;
      qProvider.removeListener(_checkNavigation);
      
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;

      LocationPermission permission = LocationPermission.denied;
      try {
        permission = await Geolocator.checkPermission();
      } catch (_) {}

      final bool locationOk = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;

      if (!locationOk) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PermissionScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    }
  }

  @override
  void dispose() {
    // We don't remove listener here because the navigation handles it,
    // but safe to try to ensure no leaks if disposed early.
    try {
      Provider.of<QuranDataProvider>(context, listen: false)
          .removeListener(_checkNavigation);
    } catch (_) {}
    _breathController.dispose();
    _shimmerController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xff0E323F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff0E323F),
        body: SafeArea(
          child: Column(
            children: [
              // ── Breathing Logo ───────────────────────────────────
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _breathController,
                    builder: (_, child) => Transform.scale(
                      scale: _breathScale.value,
                      child: child,
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 200, // Logo is now much larger
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // ── Progress Section ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 60),
                child: Consumer<QuranDataProvider>(
                  builder: (_, qProvider, __) {
                    final progress = qProvider.displayProgress;
                    final int pct = (progress * 100).toInt().clamp(0, 100);
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$pct%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                            letterSpacing: 2.0,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        _ModernProgressBar(
                          value: progress,
                          shimmer: _shimmerController,
                          color: primayColor,
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // ── Footer ───────────────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              "Developed By: ",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              "Dev'sinn Technologies",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernProgressBar extends StatelessWidget {
  final double value;
  final AnimationController shimmer;
  final Color color;

  const _ModernProgressBar({
    required this.value,
    required this.shimmer,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fillWidth = (width * value).clamp(0.0, width);

        return Container(
          height: 6,
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              // The Fill
              Container(
                width: fillWidth,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              
              // Shimmer highlight
              if (fillWidth > 30)
                AnimatedBuilder(
                  animation: shimmer,
                  builder: (_, __) {
                    final shimmerPos = (fillWidth - 50) * shimmer.value;
                    return Positioned(
                      left: shimmerPos.clamp(0.0, (fillWidth - 50) > 0 ? fillWidth - 50 : 0.0),
                      child: Container(
                        width: 50,
                        height: 6,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.white.withOpacity(0.4),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
