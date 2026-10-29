import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Provider/theme_provider.dart';
import '../Services/verse_video.dart';
import 'share_card.dart';
import 'share_preview.dart';

class KalmaDuaShare {
  static Future<File> _generateImage({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    String? arabicTitle,
    required String arabicText,
    required String translationText,
    String? englishText,
    String? translatorName,
  }) async {
    const double width = 1080;
    const double centerX = width / 2;
    const double contentWidth = 940;

    const double headerBaseHeight = 450.0;

    final titlePainter = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 60,
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
            fontSize: 100,
            fontFamily: bloc.urduFontFamily,
          ),
        ),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.center,
      );
      arabicTitlePainter.layout(maxWidth: 900);
    }

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

    const double topPadding = 100.0;
    const double dividerSpacing = 80.0;
    const double footerHeight = 250.0;

    final double totalHeight = headerBaseHeight +
        topPadding +
        arabicPainter.height +
        dividerSpacing +
        urduPainter.height +
        translatorHeight +
        footerHeight +
        120;

    final Size size = Size(width, totalHeight);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height),
        Paint()..color = Colors.white);

    final headerPaint = Paint()..color = bloc.selectedTheme;
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, headerBaseHeight), headerPaint);

    if (arabicTitlePainter != null) {
      if (title.isNotEmpty) {
        arabicTitlePainter.paint(
            canvas, Offset(centerX - (arabicTitlePainter.width / 2), 60));
        titlePainter.paint(
            canvas, Offset(centerX - (titlePainter.width / 2), 260));
      } else {
        arabicTitlePainter.paint(
            canvas, Offset(centerX - (arabicTitlePainter.width / 2), 150));
      }
    } else {
      titlePainter.paint(
          canvas, Offset(centerX - (titlePainter.width / 2), 150));
    }

    double currentY = headerBaseHeight + topPadding;

    arabicPainter.paint(
        canvas, Offset(centerX - (arabicPainter.width / 2), currentY));
    currentY += arabicPainter.height + 40;

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

    if (translatorPainter != null) {
      translatorPainter.paint(
          canvas, Offset(centerX - (translatorPainter.width / 2), currentY));
      currentY += translatorPainter.height + 25;
    }

    urduPainter.paint(
        canvas, Offset(centerX - (urduPainter.width / 2), currentY));

    double footerY = size.height - 200;

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

    final brandPainter = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'IQRA QURAN\n',
            style: TextStyle(
                color: bloc.selectedTheme,
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

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    final buffer = byteData!.buffer.asUint8List();

    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/kalmadua_share_${DateTime.now().millisecondsSinceEpoch}.png');
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
  }) {
    Future<File> makeImage(bool watermark) async {
      final file = await _generateImage(
        context: context,
        bloc: bloc,
        title: title,
        arabicTitle: arabicTitle,
        arabicText: arabicText,
        translationText: translationText,
        englishText: englishText,
        translatorName: translatorName,
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
      videoDescription: 'The video shows this card as a short clip.',
    );
  }

  static void text({
    required String title,
    required String arabicText,
    required String translationText,
  }) {
    const shareText =
        'Download IQRA QURAN: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran';
    Share.share(shareText);
  }
}
