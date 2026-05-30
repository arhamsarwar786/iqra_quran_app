import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:iqra/Provider/theme_provider.dart';
import '../providers/hajj_live_provider.dart';
import '../services/hajj_time_service.dart';

class HajjShareService {
  static const String appDownloadLink =
      "https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran";

  static Future<void> shareLiveText(BuildContext context) async {
    const String shareText = "🔴 Makkah Live is LIVE on IQRA QURAN App\n\n"
        "Watch the holy live stream now and stay spiritually connected.\n\n"
        "Check it out now.\n\n"
        "📲 Download App:\n$appDownloadLink";

    await Share.share(shareText);
  }

  static Future<File> _generateHajjImage({
    required BuildContext context,
    required ThemeProvider bloc,
    required HajjLiveProvider provider,
  }) async {
    const double width = 1080;
    const double headerHeight = 560.0;
    const double contentHeight = 480.0;
    const double footerHeight = 200.0;

    final double totalHeight = headerHeight + contentHeight + footerHeight;
    final Size size = Size(width, totalHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background - Clean White/Light Gray
    final bgPaint = Paint()..color = const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Header Gradient
    final Rect headerRect = Rect.fromLTWH(0, 0, size.width, headerHeight);
    final gradient = LinearGradient(
      colors: [bloc.selectedTheme, bloc.selectedTheme.withOpacity(0.8)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    final Paint headerPaint = Paint()
      ..shader = gradient.createShader(headerRect);
    canvas.drawRRect(
        ui.RRect.fromRectAndCorners(headerRect,
            bottomLeft: const Radius.circular(80),
            bottomRight: const Radius.circular(80)),
        headerPaint);

    // Header Content
    final isLive = provider.isLive;

    // Draw Kaaba Image in header (centered, top padding 40)
    try {
      final ByteData kaabaData =
          await rootBundle.load('assets/images/kaaba.png');
      final ui.Codec kaabaCodec = await ui.instantiateImageCodec(
          kaabaData.buffer.asUint8List(),
          targetWidth: 150);
      final ui.FrameInfo kaabaFrame = await kaabaCodec.getNextFrame();
      canvas.drawImage(kaabaFrame.image,
          Offset((width - kaabaFrame.image.width) / 2, 50), Paint());
    } catch (_) {
      final TextPainter iconPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.mosque.codePoint),
          style: TextStyle(
            color: Colors.amber,
            fontSize: 110,
            fontFamily: Icons.mosque.fontFamily,
            package: Icons.mosque.fontPackage,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      iconPainter.layout();
      iconPainter.paint(canvas, Offset((width - iconPainter.width) / 2, 50));
    }

    // y=220: PREPARING LIVE
    _drawText(canvas, isLive ? "🔴 LIVE NOW" : "PREPARING LIVE",
        offset: const Offset(width / 2, 215),
        fontSize: 32,
        weight: FontWeight.bold,
        color: Colors.white.withOpacity(0.8),
        center: true);

    // y=268: Main title
    _drawText(canvas, "Makkah Live",
        offset: const Offset(width / 2, 268),
        fontSize: 84,
        weight: FontWeight.bold,
        color: Colors.white,
        center: true);

    // y=375: Date badge pill
    const String badgeText = "26 May 2026";
    final badgePainter = TextPainter(
      text: TextSpan(
        text: badgeText,
        style: const TextStyle(
          color: Colors.amber,
          fontSize: 28,
          fontWeight: FontWeight.w600,
          letterSpacing: 2,
          fontFamily: 'Poppins',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    badgePainter.layout();
    final double badgeW = badgePainter.width + 70;
    final double badgeX = (width - badgeW) / 2;
    const double badgeY = 375;
    final Paint badgeBgPaint = Paint()..color = Colors.amber.withOpacity(0.15);
    final Paint badgeBorderPaint = Paint()
      ..color = Colors.amber.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final ui.RRect badgeRRect = ui.RRect.fromRectAndRadius(
        Rect.fromLTWH(badgeX, badgeY, badgeW, 56), const Radius.circular(28));
    canvas.drawRRect(badgeRRect, badgeBgPaint);
    canvas.drawRRect(badgeRRect, badgeBorderPaint);
    badgePainter.paint(canvas, Offset(badgeX + 35, badgeY + 13));

    // y=455: Subtitle — well above the 560 header boundary
    _drawText(canvas, "The journey of a lifetime",
        offset: const Offset(width / 2, 460),
        fontSize: 34,
        color: Colors.white.withOpacity(0.85),
        fontStyle: FontStyle.italic,
        center: true);

    // Main Content Card
    final Rect cardRect =
        Rect.fromLTWH(60, headerHeight + 60, width - 120, contentHeight - 60);
    final cardPaint = Paint()..color = Colors.white;
    canvas.drawRRect(
        ui.RRect.fromRectAndRadius(cardRect, const Radius.circular(30)),
        cardPaint);

    if (isLive) {
      final activeBorder = Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(
          ui.RRect.fromRectAndRadius(cardRect, const Radius.circular(30)),
          activeBorder);

      _drawText(canvas, "MAKKAH IS LIVE",
          offset: const Offset(width / 2, headerHeight + 110),
          fontSize: 60,
          weight: FontWeight.bold,
          color: Colors.red,
          center: true);

      final String liveText = provider.config?.description?.isNotEmpty == true
          ? provider.config!.description
          : "Download the app now and check the live Makkah stream anytime.";

      _drawText(canvas, liveText,
          offset: const Offset(width / 2, headerHeight + 200),
          fontSize: 32,
          color: const Color(0xFF2D3436),
          center: true,
          textAlign: TextAlign.center,
          maxWidth: width - 180);
    } else {
      final timeService = HajjTimeService();
      final countdown = timeService.formatCountdown(provider.remainingTime);

      _drawText(canvas, "OFFICIAL START IN",
          offset: const Offset(width / 2, headerHeight + 110),
          fontSize: 35,
          weight: FontWeight.bold,
          color: Colors.amber[700]!,
          center: true);

      _drawText(canvas, countdown,
          offset: const Offset(width / 2, headerHeight + 190),
          fontSize: 65,
          weight: FontWeight.bold,
          color: const Color(0xFF2D3436),
          fontFamily: 'monospace',
          center: true);

      final String comingSoonText = provider
                  .config?.comingSoonMessage?.isNotEmpty ==
              true
          ? provider.config!.comingSoonMessage
          : "Download the app and wait together to see the live stream in Hajj.";

      _drawText(canvas, comingSoonText,
          offset: const Offset(width / 2, headerHeight + 275),
          fontSize: 28,
          color: const Color(0xFF636E72),
          center: true,
          textAlign: TextAlign.center,
          maxWidth: width - 180);
    }

    // Download App Section inside Card
    final Paint downloadBgPaint = Paint()
      ..color = bloc.selectedTheme.withOpacity(0.1);
    final Rect downloadRect =
        Rect.fromLTWH(width / 2 - 300, headerHeight + 350, 600, 70);
    canvas.drawRRect(
        ui.RRect.fromRectAndRadius(downloadRect, const Radius.circular(35)),
        downloadBgPaint);

    _drawText(canvas, "⬇ Download 'IQRA QURAN App'",
        offset: const Offset(width / 2, headerHeight + 368),
        fontSize: 32,
        color: bloc.selectedTheme,
        weight: FontWeight.bold,
        center: true);

    // Footer
    double footerY = totalHeight - 180;
    _drawText(canvas, "IQRA QURAN",
        offset: Offset(60, footerY + 30),
        fontSize: 45,
        weight: FontWeight.bold,
        color: bloc.selectedTheme);
    _drawText(canvas, "Read & Learn Quran",
        offset: Offset(60, footerY + 90), fontSize: 30, color: Colors.grey);

    // Logo
    try {
      final String logoPath = "assets/images/iqra${bloc.iconNumber}.png";
      final ByteData logoData = await rootBundle.load(logoPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
          logoData.buffer.asUint8List(),
          targetWidth: 150);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      canvas.drawImage(
          frameInfo.image, Offset(width - 210, footerY + 20), Paint());
    } catch (_) {}

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), totalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/hajj_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    return file;
  }

  static void _drawText(
    Canvas canvas,
    String text, {
    required Offset offset,
    required double fontSize,
    Color color = Colors.black,
    FontWeight weight = FontWeight.normal,
    FontStyle fontStyle = FontStyle.normal,
    bool center = false,
    String fontFamily = 'Poppins',
    TextAlign textAlign = TextAlign.left,
    double? maxWidth,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            fontStyle: fontStyle,
            fontFamily: fontFamily),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: textAlign,
    );
    if (maxWidth != null) {
      painter.layout(maxWidth: maxWidth);
    } else {
      painter.layout();
    }
    double x = offset.dx;
    if (center) {
      x -= painter.width / 2;
    } else if (textAlign == TextAlign.right && maxWidth == null) {
      x -= painter.width;
    }
    painter.paint(canvas, Offset(x, offset.dy));
  }

  static Future<void> shareHajjCard({
    required BuildContext context,
    required ThemeProvider bloc,
    required HajjLiveProvider provider,
  }) async {
    try {
      final file = await _generateHajjImage(
        context: context,
        bloc: bloc,
        provider: provider,
      );

      if (!context.mounted) return;

      await showDialog(
        context: context,
        useSafeArea: true,
        barrierColor: Colors.black.withOpacity(0.9),
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text("Close",
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        final fallback = provider.isLive
                            ? "🔴 Makkah Live is LIVE on IQRA QURAN App! Download now: $appDownloadLink"
                            : "🕋 Makkah Live: ${HajjTimeService().formatCountdown(provider.remainingTime)} on IQRA QURAN App!\n\nDownload now: $appDownloadLink";
                        Share.shareXFiles([XFile(file.path)], text: fallback);
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("Share Now"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: bloc.selectedTheme,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder()),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(file),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
