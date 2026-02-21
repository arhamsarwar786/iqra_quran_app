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

    // Header Logic
    // If we have detailed info, title is the Surah Name, and we build a subtitle.
    String mainTitle = title;
    String? subTitle;

    if (paraNumber != null || surahNumber != null || ayatNumber != null) {
      // Build subtitle from available parts
      List<String> parts = [];
      if (paraNumber != null) parts.add("Para: $paraNumber");
      if (surahNumber != null) parts.add("Surah: $surahNumber");
      if (ayatNumber != null) parts.add("Verse: $ayatNumber");
      subTitle = parts.join("  •  ");
    }

    // Header Content Height Calculation
    const double headerBaseHeight =
        250.0; // Increased base height for two lines

    final titlePainter = TextPainter(
      text: TextSpan(
        text: mainTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 60, // Main Title (Surah Name)
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
          letterSpacing: 0.5,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    titlePainter.layout(maxWidth: 900);

    TextPainter? subTitlePainter;
    if (subTitle != null) {
      subTitlePainter = TextPainter(
        text: TextSpan(
          text: subTitle,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 32, // Subtitle
            fontWeight: FontWeight.normal,
            fontFamily: 'Roboto',
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      subTitlePainter.layout(maxWidth: 900);
    }

    // Arabic Text Height
    final arabicPainter = TextPainter(
      text: TextSpan(
        text: arabicText,
        style: TextStyle(
          color: const Color(0xff333333), // Softer darker grey/black
          fontSize: 90,
          fontFamily: bloc.arabicFontFamily,
          fontWeight: FontWeight.w400, // Reduced bold
          height: 1.6,
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
          color: Colors.grey[800], // Dark grey
          fontSize: 56,
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
            color: Colors.grey[600], // Lighter grey
            fontSize: 36,
            fontFamily: bloc.urduFontFamily,
            fontWeight: FontWeight.w400,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
      );
      translatorPainter.layout(maxWidth: contentWidth);
      translatorHeight = translatorPainter.height + 40; // Spacing
    }

    // English Text Height
    double englishHeight = 0;
    TextPainter? englishPainter;
    if (englishText != null && englishText.isNotEmpty) {
      englishPainter = TextPainter(
        text: TextSpan(
          text: englishText,
          style: TextStyle(
            color: Colors.grey[800], // Dark grey
            fontSize: 42,
            height: 1.5,
            fontFamily: 'Roboto',
            fontStyle: FontStyle.normal,
          ),
        ),
        textDirection: ui.TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      englishPainter.layout(maxWidth: contentWidth);
      englishHeight = englishPainter.height + 60; // Include padding if exists
    }

    // Footer Height
    const double footerHeight = 250.0;

    // Spacings
    const double topPadding = 120.0; // Space between header and arabic
    const double dividerSpacing =
        80.0; // Space + divider between arabic and urdu

    // Total Height Calculation
    final double totalHeight = headerBaseHeight +
        topPadding +
        arabicPainter.height +
        dividerSpacing +
        urduPainter.height +
        translatorHeight +
        englishHeight +
        footerHeight;

    // Ensure minimum height of 1920 (Standard HD)
    final double finalHeight = totalHeight < 1920 ? 1920 : totalHeight;
    final Size size = Size(width, finalHeight);

    // --- 2. Start Drawing ---
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Background - Plain White
    final bgPaint = Paint()..color = Colors.white;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Subtle Pattern
    final patternPaint = Paint()
      ..color = Colors.grey.withOpacity(0.03)
      ..strokeWidth = 2;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), patternPaint);
    }

    // --- Header Section ---
    final headerPaint = Paint()..color = bloc.selectedTheme; // Use bloc theme
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, headerBaseHeight), headerPaint);

    // Draw Main Title
    double titleY = (headerBaseHeight - titlePainter.height) / 2;
    if (subTitlePainter != null) {
      titleY = (headerBaseHeight -
              (titlePainter.height + subTitlePainter.height + 10)) /
          2;
    }
    titlePainter.paint(
        canvas, Offset(centerX - (titlePainter.width / 2), titleY));

    // Draw Subtitle
    if (subTitlePainter != null) {
      subTitlePainter.paint(
          canvas,
          Offset(centerX - (subTitlePainter.width / 2),
              titleY + titlePainter.height + 10));
    }

    // --- Content Drawing ---
    double currentY = headerBaseHeight + topPadding;

    // 1. Arabic Text
    arabicPainter.paint(
        canvas, Offset(centerX - (arabicPainter.width / 2), currentY));

    currentY += arabicPainter.height + 40; // Spacing after Arabic

    // 2. Divider
    final dividerPaint = Paint()
      ..color = bloc.selectedTheme.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(centerX - 100, currentY),
        Offset(centerX - 20, currentY), dividerPaint);
    canvas.drawCircle(Offset(centerX, currentY), 10,
        dividerPaint..style = PaintingStyle.fill);
    canvas.drawLine(
        Offset(centerX + 20, currentY),
        Offset(centerX + 100, currentY),
        dividerPaint..style = PaintingStyle.stroke);

    currentY += 40; // Spacing after Divider

    // 3. Urdu Translation
    urduPainter.paint(
        canvas, Offset(centerX - (urduPainter.width / 2), currentY));

    currentY += urduPainter.height + 20;

    // 4. Translator Name
    if (translatorPainter != null) {
      translatorPainter.paint(
          canvas, Offset(centerX - (translatorPainter.width / 2), currentY));
      currentY += translatorHeight;
    } else {
      currentY += 40;
    }

    // 5. English Translation
    if (englishPainter != null) {
      englishPainter.paint(
          canvas, Offset(centerX - (englishPainter.width / 2), currentY));
      currentY += englishHeight;
    }

    // --- Footer Section ---
    // Position footer at the bottom relative to content or absolute bottom of dynamic size
    // We'll place it at (finalHeight - 200) to ensure it's at the bottom
    double footerY = finalHeight - 200;

    // Logo Area
    const double logoSize = 120;
    try {
      // Use dynamic logo based on selected theme/iconNumber
      final String logoPath = "assets/images/iqra${bloc.iconNumber}.png";
      final ByteData logoData = await rootBundle.load(logoPath);
      final ui.Codec codec = await ui.instantiateImageCodec(
        logoData.buffer.asUint8List(),
        targetWidth: logoSize.toInt(),
      );
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      canvas.drawImage(frameInfo.image,
          Offset(size.width - logoSize - 60, footerY + 20), Paint());
    } catch (e) {
      // Fallback or ignore
      print("Error loading logo for share image: $e");
    }

    // Branding Text
    final brandPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'IQRA QURAN\n',
            style: TextStyle(
              color: bloc.selectedTheme,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const TextSpan(
            text: 'Read & Learn Quran',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 28,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
      textDirection: ui.TextDirection.ltr,
      textAlign: TextAlign.left,
    );
    brandPainter.layout();
    brandPainter.paint(canvas, Offset(60, footerY + 30));

    // Convert to image
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    // Save to temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/quran_verse_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(buffer);

    return file;
  }

  static Future<void> image({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    required String arabicText,
    required String translationText,
    String? englishText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) async {
    try {
      // Show loading indicator usually, but generation is fast.
      // Generate the image
      final file = await _generateImage(
        context: context,
        bloc: bloc,
        title: title,
        arabicText: arabicText,
        translationText: translationText,
        englishText: englishText,
        translatorName: translatorName,
        paraNumber: paraNumber,
        surahNumber: surahNumber,
        ayatNumber: ayatNumber,
      );

      if (!context.mounted) return;

      // Show preview dialog
      await showDialog(
        context: context,
        useSafeArea: true,
        barrierColor: Colors.black.withOpacity(0.9), // Darker backdrop
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero, // maximize width
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Action Buttons (Top)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Cancel Button
                      Material(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(30),
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            child: const Row(
                              children: [
                                Icon(Icons.close,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Close',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Share Button
                      Material(
                        color: bloc.selectedTheme, // Use bloc theme
                        borderRadius: BorderRadius.circular(30),
                        elevation: 3,
                        shadowColor: bloc.selectedTheme.withOpacity(0.4),
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            String shareText =
                                '$title\n\n$arabicText\n\n$translationText';
                            if (translatorName != null &&
                                translatorName.isNotEmpty) {
                              shareText += '\n($translatorName)';
                            }
                            if (englishText != null && englishText.isNotEmpty) {
                              shareText += '\n\n$englishText';
                            }
                            // Add Reference if available
                            if (paraNumber != null ||
                                surahNumber != null ||
                                ayatNumber != null) {
                              List<String> refs = [];
                              if (paraNumber != null)
                                refs.add("Para: $paraNumber");
                              if (surahNumber != null)
                                refs.add("Surah No: $surahNumber");
                              if (ayatNumber != null)
                                refs.add("Verse: $ayatNumber");
                              shareText += '\n\nReference: ${refs.join(", ")}';
                            }

                            shareText +=
                                '\n\nDownload IQRA QURAN App: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';

                            Share.shareXFiles(
                              [XFile(file.path)],
                              text: shareText,
                            );
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            child: const Row(
                              children: [
                                Icon(Icons.share_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 6),
                                Text(
                                  'Share',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Scrollable Image Area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          file,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing verse: $e')),
        );
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
}
