import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';

import '../Services/verse_video.dart';
import 'share_card.dart';
import 'share_preview.dart';
import 'share_quran.dart';

class AppShare {
  /// Verse sharing from Home and the translation cards: the same card and
  /// preview as sharing from the reading page, including the video.
  static Future<void> image({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    String? arabicTitle,
    required String arabicText,
    required String translationText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) {
    return QuranShare.image(
      context: context,
      bloc: bloc,
      title: title,
      arabicTitle: arabicTitle ?? '',
      arabicText: arabicText,
      translationText: translationText,
      translatorName: translatorName,
      paraNumber: paraNumber,
      surahNumber: surahNumber,
      ayatNumber: ayatNumber,
    );
  }

  static Future<File> _generateNamazImage({
    required BuildContext context,
    required ThemeProvider bloc,
    required String location,
    required String date,
    required List<Map<String, dynamic>> times,
  }) async {
    const double width = 1080;
    const double headerHeight = 450.0;
    const double itemHeight = 160.0;
    const double footerHeight = 250.0;

    final double totalHeight =
        headerHeight + (times.length * itemHeight) + footerHeight + 100;
    final double finalHeight = totalHeight < 1920 ? 1920 : totalHeight;
    final Size size = Size(width, finalHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background
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
    _drawText(canvas, "DAILY PRAYER TIMES",
        offset: const Offset(width / 2, 120),
        fontSize: 40,
        weight: FontWeight.bold,
        color: Colors.white.withOpacity(0.7),
        center: true);

    _drawText(canvas, location,
        offset: const Offset(width / 2, 220),
        fontSize: 70,
        weight: FontWeight.bold,
        color: Colors.white,
        center: true);

    _drawText(canvas, date,
        offset: const Offset(width / 2, 320),
        fontSize: 45,
        color: Colors.white.withOpacity(0.9),
        center: true);

    // Prayer Items
    double currentY = headerHeight + 80;
    for (var i = 0; i < times.length; i++) {
      final prayer = times[i];
      final bool isCurrent = prayer["isCurrent"] ?? false;

      // Card Background
      final Rect cardRect =
          Rect.fromLTWH(60, currentY, width - 120, itemHeight - 30);
      final cardPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
          ui.RRect.fromRectAndRadius(cardRect, const Radius.circular(30)),
          cardPaint);

      if (isCurrent) {
        final activeBorder = Paint()
          ..color = bloc.selectedTheme
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4;
        canvas.drawRRect(
            ui.RRect.fromRectAndRadius(cardRect, const Radius.circular(30)),
            activeBorder);
      }

      // Icon placeholder / indicator
      final Paint iconCirclePaint = Paint()
        ..color = isCurrent ? bloc.selectedTheme : const Color(0xFFF1F2F6);
      canvas.drawCircle(
          Offset(140, currentY + (itemHeight - 30) / 2), 45, iconCirclePaint);

      // Name
      _drawText(canvas, prayer["name"],
          offset: Offset(220, currentY + 35),
          fontSize: 48,
          weight: FontWeight.bold,
          color: const Color(0xFF2D3436));

      if (isCurrent) {
        _drawText(canvas, "Active Now",
            offset: Offset(220, currentY + 100),
            fontSize: 30,
            weight: FontWeight.bold,
            color: bloc.selectedTheme);
      }

      // Time
      _drawText(canvas, prayer["time"],
          offset: Offset(width - 120, currentY + 45),
          fontSize: 52,
          weight: FontWeight.w900,
          color: isCurrent ? bloc.selectedTheme : const Color(0xFF636E72),
          textAlign: TextAlign.right);

      currentY += itemHeight;
    }

    // Footer
    double footerY = finalHeight - 200;
    _drawText(canvas, "IQRA QURAN",
        offset: Offset(80, footerY + 30),
        fontSize: 45,
        weight: FontWeight.bold,
        color: bloc.selectedTheme);
    _drawText(canvas, "Read & Learn Quran",
        offset: Offset(80, footerY + 90), fontSize: 30, color: Colors.grey);

    // Logo
    try {
      final String logoPath = "assets/images/iqra${bloc.iconNumber}.png";
      final ByteData logoData = await rootBundle.load(logoPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
          logoData.buffer.asUint8List(),
          targetWidth: 150);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      canvas.drawImage(
          frameInfo.image, Offset(width - 230, footerY + 20), Paint());
    } catch (_) {}

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), finalHeight.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/namaz_share_${DateTime.now().millisecondsSinceEpoch}.png');
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
    bool center = false,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: weight,
            fontFamily: 'Poppins'),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: textAlign,
    );
    painter.layout();
    double x = offset.dx;
    if (center)
      x -= painter.width / 2;
    else if (textAlign == TextAlign.right) x -= painter.width;
    painter.paint(canvas, Offset(x, offset.dy));
  }

  static Future<void> namazTimes({
    required BuildContext context,
    required ThemeProvider bloc,
    required String location,
    required String date,
    required List<Map<String, dynamic>> times,
  }) {
    Future<File> makeImage(bool watermark) async {
      final file = await _generateNamazImage(
        context: context,
        bloc: bloc,
        location: location,
        date: date,
        times: times,
      );
      if (!watermark) return file;
      return ShareWatermark.apply(file, iconNumber: bloc.iconNumber);
    }

    return SharePreview.show(
      context,
      theme: bloc.selectedTheme,
      makeImage: makeImage,
      makeVideo: (watermark, onProgress) async => VerseVideo.fromImage(
        await makeImage(watermark),
        background: Color.lerp(bloc.selectedTheme, Colors.black, 0.35)!,
        onProgress: onProgress,
      ),
      videoDescription: 'The video shows these prayer times as a short clip.',
      text:
          "Daily Prayer Times for $location\n$date\n\nDownload IQRA QURAN App: "
          "https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran",
    );
  }

  static void text({
    required String title,
    required String arabicText,
    required String translationText,
    String? surahNumber,
    String? ayatNumber,
  }) {
    const shareText =
        'Download IQRA QURAN: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';
    Share.share(shareText);
  }
}
