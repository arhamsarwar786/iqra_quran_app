import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../Provider/theme_provider.dart';
import '../Utils/share_card.dart';
import 'verse_recitation_timing.dart';

typedef VideoProgress = void Function(String stage, double progress);

/// Makes a shareable video of a verse: the share card with its recitation,
/// each word highlighted as it is recited.
///
/// Frames are drawn here; the MP4 is encoded natively (Android only).
class VerseVideo {
  static const MethodChannel _channel = MethodChannel(
    'com.devsinntechnologies.iqraquran/verse_video',
  );
  static const double _width = 1080;
  static const double _height = 1920;
  static const int _fps = 30;

  static bool get isSupported => Platform.isAndroid;

  static Future<File> create({
    required ThemeProvider bloc,
    required String title,
    required String arabicTitle,
    required String arabicText,
    required String translationText,
    required int surahId,
    required int ayahNumber,
    String? translatorName,
    String? paraNumber,
    bool watermark = true,
    VideoProgress? onProgress,
  }) async {
    onProgress?.call('Preparing the recitation…', 0.02);
    final recitation = await VerseRecitation.load(surahId, ayahNumber);

    // The verse exactly as the image shows it: the app's own text, font,
    // pause marks and verse number, with the recitation's timings moved
    // onto its words.
    final words = arabicText.trim().split(RegExp(r'\s+'));
    final timings = recitation.timingsFor(words);
    final card = await ShareCard.build(
      bloc: bloc,
      title: title,
      arabicTitle: arabicTitle,
      arabicText: words.join(' '),
      arabicWords: words,
      watermark: watermark,
      translationText: translationText,
      translatorName: translatorName,
      paraNumber: paraNumber,
      surahNumber: '$surahId',
      ayatNumber: '$ayahNumber',
    );

    // Frames go in a folder of their own, deleted once encoded; finished
    // videos stay so the preview can switch between them.
    final dir = Directory(
      '${(await getTemporaryDirectory()).path}/verse_video',
    );
    final framesDir = Directory(
      '${dir.path}/frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await framesDir.create(recursive: true);

    // The first frame has nothing highlighted; then one frame per word,
    // shown from the moment that word is recited.
    final highlights = <int?>[null, ...timings.map((t) => t.word)];
    final starts = <int>[0, ...timings.map((t) => t.startMs)];
    final placements = _place(card, highlights);
    final background = Color.lerp(bloc.selectedTheme, Colors.black, 0.35)!;

    final framePaths = <String>[];
    for (var i = 0; i < highlights.length; i++) {
      final png = await _renderFrame(
        card,
        highlights[i],
        placements[i],
        background,
      );
      final file = File('${framesDir.path}/frame_$i.png');
      await file.writeAsBytes(png);
      framePaths.add(file.path);
      onProgress?.call(
        'Preparing the video…',
        0.05 + 0.4 * (i + 1) / highlights.length,
      );
    }

    final output = File(
      '${dir.path}/IQRA_Quran_${surahId}_$ayahNumber'
      '${watermark ? '' : '_plain'}.mp4',
    );
    try {
      await _encode(
        frames: framePaths,
        frameStartsMs: starts,
        audioPath: recitation.audio.path,
        output: output,
        onProgress: (p) =>
            onProgress?.call('Creating the video…', 0.45 + 0.55 * p),
      );
    } finally {
      await framesDir.delete(recursive: true);
    }
    return output;
  }

  /// A short silent video of a card that has no recitation: the card on
  /// screen with a slow, gentle zoom.
  static Future<File> fromImage(
    File image, {
    required Color background,
    int seconds = 8,
    VideoProgress? onProgress,
  }) async {
    onProgress?.call('Preparing the video…', 0.05);
    final codec = await ui.instantiateImageCodec(await image.readAsBytes());
    final card = (await codec.getNextFrame()).image;
    final scale = [
      _width / card.width,
      _height / card.height,
    ].reduce((a, b) => a < b ? a : b);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _width, _height),
      Paint()..color = background,
    );
    final w = card.width * scale;
    final h = card.height * scale;
    canvas.drawImageRect(
      card,
      Rect.fromLTWH(0, 0, card.width.toDouble(), card.height.toDouble()),
      Rect.fromLTWH((_width - w) / 2, (_height - h) / 2, w, h),
      Paint()..filterQuality = FilterQuality.high,
    );
    final frame = await recorder.endRecording().toImage(
      _width.toInt(),
      _height.toInt(),
    );
    final png = await frame.toByteData(format: ui.ImageByteFormat.png);

    final dir = Directory('${(await getTemporaryDirectory()).path}/card_video');
    await dir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final framePath = '${dir.path}/frame_$stamp.png';
    await File(framePath).writeAsBytes(png!.buffer.asUint8List());
    final output = File('${dir.path}/IQRA_$stamp.mp4');
    try {
      await _encode(
        frames: [framePath],
        frameStartsMs: const [0],
        durationMs: seconds * 1000,
        zoomTo: 1.06,
        output: output,
        onProgress: (p) =>
            onProgress?.call('Creating the video…', 0.1 + 0.9 * p),
      );
    } finally {
      await File(framePath).delete();
    }
    return output;
  }

  static Future<void> _encode({
    required List<String> frames,
    required List<int> frameStartsMs,
    required File output,
    String? audioPath,
    int durationMs = 0,
    double zoomTo = 1,
    void Function(double progress)? onProgress,
  }) async {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'progress') {
        onProgress?.call((call.arguments as num).toDouble());
      }
    });
    try {
      await _channel.invokeMethod('encode', {
        'frames': frames,
        'frameStartsMs': frameStartsMs,
        'audioPath': audioPath,
        'durationMs': durationMs,
        'zoomTo': zoomTo,
        'outputPath': output.path,
        'width': _width.toInt(),
        'height': _height.toInt(),
        'fps': _fps,
      });
    } finally {
      _channel.setMethodCallHandler(null);
    }
  }

  /// Where the card sits in each frame. Short cards are centred; cards a
  /// little too tall are scaled down; long ones keep full size and scroll so
  /// the word being recited stays in view.
  static List<_Placement> _place(ShareCard card, List<int?> highlights) {
    final h = card.size.height;
    if (h <= _height) {
      return List.filled(
        highlights.length,
        _Placement(1, 0, (_height - h) / 2),
      );
    }
    if (h * 0.8 <= _height) {
      final scale = _height / h;
      return List.filled(
        highlights.length,
        _Placement(scale, (_width - ShareCard.width * scale) / 2, 0),
      );
    }
    final placements = <_Placement>[];
    var top = 0.0;
    for (final word in highlights) {
      final rect = word == null ? null : card.wordBounds(word);
      // Scroll only when the word leaves the middle half of the frame.
      if (rect != null &&
          (rect.top < top + _height * 0.25 ||
              rect.bottom > top + _height * 0.75)) {
        top = (rect.center.dy - _height * 0.4).clamp(0.0, h - _height);
      }
      placements.add(_Placement(1, 0, -top));
    }
    return placements;
  }

  static Future<Uint8List> _renderFrame(
    ShareCard card,
    int? highlight,
    _Placement placement,
    Color background,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, _width, _height),
      Paint()..color = background,
    );
    canvas.save();
    canvas.translate(placement.dx, placement.dy);
    canvas.scale(placement.scale);
    card.paint(canvas, highlight: highlight);
    canvas.restore();
    final image = await recorder.endRecording().toImage(
      _width.toInt(),
      _height.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }
}

class _Placement {
  final double scale;
  final double dx;
  final double dy;

  const _Placement(this.scale, this.dx, this.dy);
}
