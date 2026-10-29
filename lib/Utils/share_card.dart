import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../Provider/theme_provider.dart';

/// The verse card used for sharing, as an image and as video frames.
///
/// Laid out once; [paint] can then draw it with any word highlighted. Only
/// the colour changes between highlights, so the layout never moves.
class ShareCard {
  static const double width = 1080;
  static const double _centerX = width / 2;
  static const double _contentWidth = 940;
  static const double _headerBaseHeight = 450.0;
  static const double _topPadding = 100.0;
  static const double _dividerSpacing = 80.0;
  static const double _footerHeight = 250.0;
  static const double _logoSize = 140;
  static const double _watermarkSize = 640;
  static const double _watermarkOpacity = 0.05;

  final ThemeProvider bloc;
  final String arabicText;

  /// When set, the Arabic is drawn from these words so each can be
  /// highlighted; otherwise [arabicText] is drawn as is.
  final List<String>? arabicWords;
  final TextPainter _title;
  final TextPainter _arabicTitle;
  final TextPainter _urdu;
  final TextPainter? _translator;
  final TextPainter? _reference;
  final TextPainter _brand;
  final ui.Image? _logo;
  final ui.Image? _watermark;
  final Size size;

  // Character range of each word inside the Arabic paragraph.
  final List<TextRange> _wordRanges;

  ShareCard._({
    required this.bloc,
    required this.arabicText,
    required this.arabicWords,
    required TextPainter title,
    required TextPainter arabicTitle,
    required TextPainter urdu,
    required TextPainter? translator,
    required TextPainter? reference,
    required TextPainter brand,
    required ui.Image? logo,
    required ui.Image? watermark,
    required this.size,
    required List<TextRange> wordRanges,
  })  : _title = title,
        _arabicTitle = arabicTitle,
        _urdu = urdu,
        _translator = translator,
        _reference = reference,
        _brand = brand,
        _logo = logo,
        _watermark = watermark,
        _wordRanges = wordRanges;

  static Future<ShareCard> build({
    required ThemeProvider bloc,
    required String title,
    required String arabicTitle,
    required String arabicText,
    required String translationText,
    List<String>? arabicWords,
    bool watermark = true,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) async {
    final titlePainter = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.w900,
          fontFamily: bloc.urduFontFamily,
          letterSpacing: 1.5,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: 900);

    final arabicTitlePainter = TextPainter(
      text: TextSpan(
        text: arabicTitle,
        style: TextStyle(
          color: Colors.white.withOpacity(0.95),
          fontSize: 100,
          fontFamily: bloc.arabicFontFamily,
        ),
      ),
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: 900);

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
    )..layout(maxWidth: _contentWidth);

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
      )..layout(maxWidth: _contentWidth);
    }

    final List<String> refParts = [];
    if (paraNumber != null && paraNumber != "null") {
      refParts.add("Para: $paraNumber");
    }
    if (surahNumber != null && surahNumber != "null") {
      refParts.add("Surah: $surahNumber");
    }
    if (ayatNumber != null && ayatNumber != "null") {
      refParts.add("Verse: $ayatNumber");
    }
    TextPainter? referencePainter;
    if (refParts.isNotEmpty) {
      referencePainter = TextPainter(
        text: TextSpan(
          text: refParts.join("   •   "),
          style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins'),
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
    }

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
    )..layout();

    ui.Image? logo;
    ui.Image? watermarkImage;
    try {
      final ByteData logoData =
          await rootBundle.load("assets/images/iqra${bloc.iconNumber}.png");
      final bytes = logoData.buffer.asUint8List();
      logo = await _decode(bytes, _logoSize);
      if (watermark) watermarkImage = await _decode(bytes, _watermarkSize);
    } catch (_) {}

    final wordRanges = <TextRange>[];
    if (arabicWords != null) {
      var offset = 0;
      for (final word in arabicWords) {
        wordRanges.add(TextRange(start: offset, end: offset + word.length));
        offset += word.length + 1;
      }
    }

    final arabicHeight =
        _layoutArabic(bloc, arabicText, arabicWords, null).height;
    final translatorHeight =
        translatorPainter == null ? 0 : translatorPainter.height + 40;
    final height = _headerBaseHeight +
        _topPadding +
        arabicHeight +
        _dividerSpacing +
        urduPainter.height +
        translatorHeight +
        _footerHeight +
        120;
    return ShareCard._(
      bloc: bloc,
      arabicText: arabicText,
      arabicWords: arabicWords,
      title: titlePainter,
      arabicTitle: arabicTitlePainter,
      urdu: urduPainter,
      translator: translatorPainter,
      reference: referencePainter,
      brand: brandPainter,
      logo: logo,
      watermark: watermarkImage,
      size: Size(width, height),
      wordRanges: wordRanges,
    );
  }

  int get wordCount => _wordRanges.length;

  static const double _arabicTop = _headerBaseHeight + _topPadding;

  TextPainter _arabicPainter(int? highlight) =>
      _layoutArabic(bloc, arabicText, arabicWords, highlight);

  static TextPainter _layoutArabic(ThemeProvider bloc, String arabicText,
      List<String>? words, int? highlight) {
    final base = TextStyle(
      color: const Color(0xff222222),
      fontSize: 85,
      fontFamily: bloc.arabicFontFamily,
      height: 1.7,
    );
    final InlineSpan text = words == null
        ? TextSpan(text: arabicText, style: base)
        : TextSpan(style: base, children: [
            for (var i = 0; i < words.length; i++) ...[
              TextSpan(
                text: words[i],
                style: i == highlight
                    ? TextStyle(color: bloc.selectedTheme)
                    : null,
              ),
              if (i < words.length - 1) const TextSpan(text: ' '),
            ],
          ]);
    return TextPainter(
      text: text,
      textDirection: ui.TextDirection.rtl,
      textAlign: TextAlign.center,
    )..layout(maxWidth: _contentWidth);
  }

  static Future<ui.Image> _decode(Uint8List bytes, double width) async {
    final codec =
        await ui.instantiateImageCodec(bytes, targetWidth: width.toInt());
    return (await codec.getNextFrame()).image;
  }

  /// Area of word [index] on the card, for keeping it in view.
  Rect? wordBounds(int index) {
    if (index < 0 || index >= _wordRanges.length) return null;
    final painter = _arabicPainter(null);
    final boxes = painter.getBoxesForSelection(TextSelection(
        baseOffset: _wordRanges[index].start,
        extentOffset: _wordRanges[index].end));
    if (boxes.isEmpty) return null;
    final origin = Offset(_centerX - painter.width / 2, _arabicTop);
    return boxes
        .map((b) => b.toRect().shift(origin))
        .reduce((a, b) => a.expandToInclude(b));
  }

  void paint(Canvas canvas, {int? highlight}) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, _headerBaseHeight),
        Paint()..color = bloc.selectedTheme);

    _arabicTitle.paint(canvas, Offset(_centerX - (_arabicTitle.width / 2), 60));
    _title.paint(canvas, Offset(_centerX - (_title.width / 2), 260));

    final reference = _reference;
    if (reference != null) {
      final refRect = Rect.fromCenter(
          center: const Offset(_centerX, _headerBaseHeight - 70),
          width: 800,
          height: 70);
      canvas.drawRRect(
          ui.RRect.fromRectAndRadius(refRect, const Radius.circular(35)),
          Paint()..color = Colors.white.withOpacity(0.15));
      reference.paint(canvas,
          Offset(_centerX - (reference.width / 2), _headerBaseHeight - 90));
    }

    // A very light logo behind the verse, marking the card as IQRA's.
    final watermark = _watermark;
    if (watermark != null) {
      const bodyTop = _headerBaseHeight;
      final bodyBottom = size.height - _footerHeight + 50;
      final side = math.min(_watermarkSize, (bodyBottom - bodyTop) * 0.85);
      canvas.drawImageRect(
        watermark,
        Rect.fromLTWH(
            0, 0, watermark.width.toDouble(), watermark.height.toDouble()),
        Rect.fromCenter(
          center: Offset(_centerX, (bodyTop + bodyBottom) / 2),
          width: side,
          height: side * watermark.height / watermark.width,
        ),
        Paint()
          ..color = Colors.white.withOpacity(_watermarkOpacity)
          ..filterQuality = FilterQuality.medium,
      );
    }

    // A soft marker behind the word being recited.
    final marked = highlight == null ? null : wordBounds(highlight);
    if (marked != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(marked.inflate(10), const Radius.circular(18)),
        Paint()..color = bloc.selectedTheme.withOpacity(0.12),
      );
    }

    final arabic = _arabicPainter(highlight);
    arabic.paint(canvas, Offset(_centerX - (arabic.width / 2), _arabicTop));
    double currentY = _arabicTop + arabic.height + 40;

    final dividerPaint = Paint()
      ..color = bloc.selectedTheme.withOpacity(0.2)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(_centerX - 150, currentY),
        Offset(_centerX - 30, currentY), dividerPaint);
    canvas.drawCircle(Offset(_centerX, currentY), 10,
        dividerPaint..style = PaintingStyle.fill);
    canvas.drawLine(
        Offset(_centerX + 30, currentY),
        Offset(_centerX + 150, currentY),
        dividerPaint..style = PaintingStyle.stroke);
    currentY += 60;

    final translator = _translator;
    if (translator != null) {
      translator.paint(
          canvas, Offset(_centerX - (translator.width / 2), currentY));
      currentY += translator.height + 25;
    }
    _urdu.paint(canvas, Offset(_centerX - (_urdu.width / 2), currentY));

    final footerY = size.height - 200;
    final logo = _logo;
    if (logo != null) {
      canvas.drawImage(
          logo, Offset(size.width - _logoSize - 80, footerY + 10), Paint());
    }
    _brand.paint(canvas, Offset(80, footerY + 30));
  }

  Future<Uint8List> toPng({int? highlight}) async {
    final recorder = ui.PictureRecorder();
    paint(Canvas(recorder), highlight: highlight);
    final image = await recorder
        .endRecording()
        .toImage(size.width.toInt(), size.height.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}

/// Adds the light logo watermark to a finished share image, over its
/// content area (leaving the header and footer clear).
class ShareWatermark {
  static Future<File> apply(
    File image, {
    required String iconNumber,
    double headerHeight = 450,
    double footerHeight = 250,
  }) async {
    final source =
        await (await ui.instantiateImageCodec(await image.readAsBytes()))
            .getNextFrame();
    final card = source.image;
    final logoData = await rootBundle.load("assets/images/iqra$iconNumber.png");
    final logo = await ShareCard._decode(
        logoData.buffer.asUint8List(), ShareCard._watermarkSize);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImage(card, Offset.zero, Paint());
    final top = headerHeight;
    final bottom = card.height - footerHeight;
    final side = math.min(math.min(ShareCard._watermarkSize, card.width * 0.6),
        (bottom - top) * 0.85);
    canvas.drawImageRect(
      logo,
      Rect.fromLTWH(0, 0, logo.width.toDouble(), logo.height.toDouble()),
      Rect.fromCenter(
        center: Offset(card.width / 2, (top + bottom) / 2),
        width: side,
        height: side * logo.height / logo.width,
      ),
      Paint()
        ..color = Colors.white.withOpacity(ShareCard._watermarkOpacity)
        ..filterQuality = FilterQuality.medium,
    );
    final result =
        await recorder.endRecording().toImage(card.width, card.height);
    final bytes = await result.toByteData(format: ui.ImageByteFormat.png);
    final out = File(image.path.replaceFirst(RegExp(r'\.png$'), '_wm.png'));
    await out.writeAsBytes(bytes!.buffer.asUint8List());
    return out;
  }
}
