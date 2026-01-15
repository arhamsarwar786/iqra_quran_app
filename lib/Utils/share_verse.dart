


  import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';


class AppShare {

  static Future<void> image(BuildContext context, ThemeProvider bloc) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(1080, 1920);

      // Background gradient
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          bloc.selectedSecondary,
          Colors.white,
        ],
      );
      
      final paint = Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

      // Draw header background
      final headerPaint = Paint()..color = Theme.of(context).primaryColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(60, 100, 960, 150),
          const Radius.circular(30),
        ),
        headerPaint,
      );

      // Load and draw logo
      try {
        final ByteData logoData = await rootBundle.load('assets/images/logo.png');
        final ui.Codec codec = await ui.instantiateImageCodec(
          logoData.buffer.asUint8List(),
          targetWidth: 100,
        );
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        canvas.drawImage(frameInfo.image, const Offset(100, 125), Paint());
      } catch (e) {
        print('Logo not found: $e');
      }

      // Draw "IQRA QURAN" text
      final appNamePainter = TextPainter(
        text: const TextSpan(
          text: 'IQRA QURAN',
          style: TextStyle(
            color: Colors.white,
            fontSize: 48,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      appNamePainter.layout();
      appNamePainter.paint(canvas, const Offset(220, 140));

      // Draw "Daily Verse" subtitle
      final subtitlePainter = TextPainter(
        text: const TextSpan(
          text: 'Daily Verse',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 32,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      subtitlePainter.layout();
      subtitlePainter.paint(canvas, const Offset(220, 190));

      // Draw decorative border
      final borderPaint = Paint()
        ..color = Theme.of(context).primaryColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 320, 920, 1200),
          const Radius.circular(40),
        ),
        borderPaint,
      );

      // Draw content background
      final contentPaint = Paint()..color = Colors.white.withOpacity(0.95);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(80, 320, 920, 1200),
          const Radius.circular(40),
        ),
        contentPaint,
      );

      // Draw "Surah Al-Baqarah" header
      final surahPainter = TextPainter(
        text: TextSpan(
          text: 'Surah Al-Baqarah (2:2)',
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 42,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      surahPainter.layout();
      surahPainter.paint(canvas, const Offset(140, 380));

      // Draw Arabic text
      final arabicPainter = TextPainter(
        text: TextSpan(
          text: 'ذٰلِكَ الۡڪِتٰبُ لَا رَيۡبَ ۛۚ  ۖ فِيۡهِ ۛۚ\nهُدًى لِّلۡمُتَّقِيۡنَۙ‏',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 72,
            fontFamily: bloc.arabicFontFamily,
            fontWeight: FontWeight.w600,
            height: 2.0,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 3,
      );
      arabicPainter.layout(maxWidth: 820);
      arabicPainter.paint(canvas, const Offset(130, 520));

      // Draw Urdu translation
      final urduPainter = TextPainter(
        text: TextSpan(
          text: 'یہ اللہ کی کتاب ہے، اس میں کوئی شک نہیں\nہدایت ہے اُن پرہیز گار لوگوں کے لیے',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 48,
            fontFamily: bloc.urduFontFamily,
            height: 1.8,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
        maxLines: 3,
      );
      urduPainter.layout(maxWidth: 820);
      urduPainter.paint(canvas, const Offset(130, 920));

      // Draw decorative line
      final linePaint = Paint()
        ..color = Theme.of(context).primaryColor.withOpacity(0.5)
        ..strokeWidth = 2;
      canvas.drawLine(
        const Offset(200, 1180),
        const Offset(880, 1180),
        linePaint,
      );

      // Draw English translation
      final englishPainter = TextPainter(
        text: const TextSpan(
          text: 'This is the Book about which there is no doubt,\na guidance for those conscious of Allah',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 36,
            height: 1.6,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
      );
      englishPainter.layout(maxWidth: 820);
      englishPainter.paint(canvas, const Offset(130, 1230));

      // Draw footer
      final footerPainter = TextPainter(
        text: TextSpan(
          text: 'Download IQRA QURAN App',
          style: TextStyle(
            color: bloc.selectedTheme,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      footerPainter.layout();
      footerPainter.paint(canvas, const Offset(280, 1720));

      // Convert to image
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/quran_verse_${DateTime.now().millisecondsSinceEpoch}.png');
      await file.writeAsBytes(buffer);

      // Share the image
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Quran Daily Verse - Surah Al-Baqarah (2:2)\n\nذٰلِكَ الۡڪِتٰبُ لَا رَيۡبَ ۛۚ  ۖ فِيۡهِ ۛۚ هُدًى لِّلۡمُتَّقِيۡنَۙ‏\n\nYeh Allah ki kitaab hai, is mein koi shak nahi, hidayat hai un parhezgaar logon ke liye.\n\nDownload IQRA QURAN App',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sharing verse: $e')),
      );
    }
  }


}
