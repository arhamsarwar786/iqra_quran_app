import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import 'package:share_plus/share_plus.dart';

class AppShare {
  static Future<File> _generateImage({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    String? arabicTitle,
    required String arabicText,
    required String translationText,
    String? englishText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) async {
    const double width = 1080;
    const double centerX = width / 2;
    const double contentWidth = 940; // width - padding

    // --- 1. Pre-calculate Heights ---

    // Header Content Height Calculation
    const double headerBaseHeight = 450.0; // Fixed large header height

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 40, // Reduced from 100
          fontWeight: FontWeight.w900,
          fontFamily: bloc.urduFontFamily,
          letterSpacing: 1.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    );
    titlePainter.layout(maxWidth: 900);

    TextPainter? arabicTitlePainter;
    if (arabicTitle != null) {
      arabicTitlePainter = TextPainter(
        text: TextSpan(
          text: arabicTitle,
          style: TextStyle(
            color: Colors.white.withOpacity(0.95),
            fontSize: 100, // Increased from 70
            fontFamily: bloc.arabicFontFamily,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
      );
      arabicTitlePainter.layout(maxWidth: 900);
    }

    // Arabic Text Height
    final arabicPainter = TextPainter(
      text: TextSpan(
        text: arabicText,
        style: TextStyle(
          color: const Color(0xff222222),
          fontSize: 85,
          fontFamily: bloc.arabicFontFamily,
          height: 1.7,
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    arabicPainter.layout(maxWidth: contentWidth);

    // Urdu Text Height
    final urduPainter = TextPainter(
      text: TextSpan(
        text: translationText,
        style: TextStyle(
          color: const Color(0xff444444),
          fontSize: 54,
          fontFamily: bloc.urduFontFamily,
          height: 1.8,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    urduPainter.layout(maxWidth: contentWidth);

    // Translator Name Height
    double translatorHeight = 0;
    TextPainter? translatorPainter;
    if (translatorName != null && translatorName.isNotEmpty) {
      translatorPainter = TextPainter(
        text: TextSpan(
          text: translatorName,
          style: TextStyle(
            color: bloc.selectedTheme.withOpacity(0.7),
            fontSize: 34,
            fontFamily: bloc.urduFontFamily,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
      );
      translatorPainter.layout(maxWidth: contentWidth);
      translatorHeight = translatorPainter.height + 40;
    }

    // Spacings
    const double topPadding = 100.0;
    const double dividerSpacing = 80.0;
    const double footerHeight = 250.0;

    // Total Height Calculation
    final double totalHeight = headerBaseHeight +
        topPadding +
        arabicPainter.height +
        dividerSpacing +
        urduPainter.height +
        translatorHeight +
        footerHeight +
        120; // Extra buffer

    final Size size = Size(width, totalHeight);

    // --- 2. Start Drawing ---
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background - Clean White
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white);

    // --- Header Section ---
    final headerPaint = Paint()..color = bloc.selectedTheme;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, headerBaseHeight), headerPaint);

    // Draw Titles
    final bool isQuran = surahNumber != null && surahNumber != "null";

    if (arabicTitlePainter != null) {
      if (isQuran) {
        // For Quran: Arabic Surah Name on top, English Name below
        arabicTitlePainter.paint(
            canvas,
            Offset(centerX - (arabicTitlePainter.width / 2),
                60)); // Arabic Name on top
        titlePainter.paint(
            canvas,
            Offset(
                centerX - (titlePainter.width / 2), 260)); // English Name below
      } else {
        // For Kalma/Dua: Arabic Name on top, English Title below
        arabicTitlePainter.paint(
            canvas,
            Offset(centerX - (arabicTitlePainter.width / 2),
                60)); // Arabic Name on top
        titlePainter.paint(
            canvas,
            Offset(
                centerX - (titlePainter.width / 2), 260)); // English Name below
      }
    } else {
      titlePainter.paint(
          canvas, Offset(centerX - (titlePainter.width / 2), 150));
    }

    // --- Reference Box ---
    final List<String> refParts = [];
    if (paraNumber != null && paraNumber != "null")
      refParts.add("Para: $paraNumber");
    if (surahNumber != null && surahNumber != "null")
      refParts.add("Surah: $surahNumber");
    if (ayatNumber != null && ayatNumber != "null")
      refParts.add("Verse: $ayatNumber");

    if (refParts.isNotEmpty) {
      final String refText = refParts.join("   •   ");
      final refBoxPaint = Paint()..color = Colors.white.withOpacity(0.15);
      final refRect = Rect.fromCenter(
          center: Offset(centerX, headerBaseHeight - 70),
          width: 800,
          height: 70);
      canvas.drawRRect(
          ui.RRect.fromRectAndRadius(refRect, const Radius.circular(35)),
          refBoxPaint);

      final refPainter = TextPainter(
        text: TextSpan(
          text: refText,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'Roboto'),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      refPainter.layout();
      refPainter.paint(canvas,
          Offset(centerX - (refPainter.width / 2), headerBaseHeight - 90));
    }

    // --- Content Drawing ---
    double currentY = headerBaseHeight + topPadding;

    // 1. Arabic Text
    arabicPainter.paint(
        canvas, Offset(centerX - (arabicPainter.width / 2), currentY));
    currentY += arabicPainter.height + 40;

    // 2. Divider Decor
    final dividerPaint = Paint()
      ..color = bloc.selectedTheme.withOpacity(0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(centerX - 150, currentY),
        Offset(centerX - 30, currentY), dividerPaint);
    canvas.drawCircle(Offset(centerX, currentY), 10,
        dividerPaint..style = PaintingStyle.fill);
    canvas.drawLine(
        Offset(centerX + 30, currentY),
        Offset(centerX + 150, currentY),
        dividerPaint..style = PaintingStyle.stroke);

    currentY += 60;

    // 3. Translator Info and Translation
    if (translatorPainter != null) {
      translatorPainter.paint(
          canvas, Offset(centerX - (translatorPainter.width / 2), currentY));
      currentY += translatorPainter.height + 25;
    }

    urduPainter.paint(
        canvas, Offset(centerX - (urduPainter.width / 2), currentY));

    // --- Footer Section ---
    double footerY = size.height - 200;

    // Logo Area
    const double logoSize = 140;
    try {
      final String logoPath = "assets/images/iqra${bloc.iconNumber}.png";
      final ByteData logoData = await rootBundle.load(logoPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(),
        targetWidth: logoSize.toInt(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      canvas.drawImage(frameInfo.image,
          Offset(size.width - logoSize - 80, footerY + 10), Paint());
    } catch (_) {}

    // Branding Text
    final brandPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'IQRA QURAN\n',
            style: TextStyle(
                color: bloc.selectedTheme,
                // fontFamily: bloc.urduFontFamily,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 1.2),
          ),
          const TextSpan(
            text: 'Read & Learn Quran on Google Play Store',
            style: TextStyle(
                color: Colors.grey,
                fontSize: 28,
                fontWeight: FontWeight.normal),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
    );
    brandPainter.layout();
    brandPainter.paint(canvas, Offset(80, footerY + 30));

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/iqra_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);

    return file;
  }

  static Future<void> image({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    String? arabicTitle,
    required String arabicText,
    required String translationText,
    String? englishText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) async {
    try {
      final file = await _generateImage(
        context: context,
        bloc: bloc,
        title: title,
        arabicTitle: arabicTitle,
        arabicText: arabicText,
        translationText: translationText,
        englishText: englishText,
        translatorName: translatorName,
        paraNumber: paraNumber,
        surahNumber: surahNumber,
        ayatNumber: ayatNumber,
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                      label: const Text('Close',
                          style: TextStyle(color: Colors.white)),
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        String reference = "";
                        if (surahNumber != null && surahNumber != "null") {
                          reference = " (Surah: $title, Verse: $ayatNumber)";
                        }
                        String shareText =
                            '${title.toUpperCase()}$reference\n\n$arabicText\n\n$translationText\n\nDownload IQRA QURAN: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';
                        Share.shareXFiles([XFile(file.path)], text: shareText);
                      },
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share Now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bloc.selectedTheme,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.file(file),
                  ),
                ),
              ),
              const SizedBox(height: 30),
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
            fontFamily: 'Roboto'),
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
  }) async {
    try {
      final file = await _generateNamazImage(
        context: context,
        bloc: bloc,
        location: location,
        date: date,
        times: times,
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
                        Share.shareXFiles([XFile(file.path)],
                            text:
                                "Daily Prayer Times for $location\n$date\n\nDownload IQRA QURAN App: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran");
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text("Share Now"),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: bloc.selectedTheme,
                          foregroundColor: Colors.white,
                          shape: StadiumBorder()),
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

  static void text({
    required String title,
    required String arabicText,
    required String translationText,
    String? surahNumber,
    String? ayatNumber,
  }) {
    String reference = "";
    if (surahNumber != null && surahNumber != "null") {
      reference = " (Surah: $title, Verse: $ayatNumber)";
    }
    String shareText =
        '${title.toUpperCase()}$reference\n\n$arabicText\n\n$translationText\n\nDownload IQRA QURAN: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';
    Share.share(shareText);
  }
}
