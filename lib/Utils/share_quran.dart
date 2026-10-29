import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../Provider/theme_provider.dart';
import '../Services/verse_video.dart';
import 'share_card.dart';
import 'share_preview.dart';

class QuranShare {
  static Future<File> _generateImage({
    required ThemeProvider bloc,
    required String title,
    required String arabicTitle,
    required String arabicText,
    required String translationText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
    bool watermark = true,
  }) async {
    final card = await ShareCard.build(
      bloc: bloc,
      title: title,
      arabicTitle: arabicTitle,
      arabicText: arabicText,
      translationText: translationText,
      translatorName: translatorName,
      paraNumber: paraNumber,
      surahNumber: surahNumber,
      ayatNumber: ayatNumber,
      watermark: watermark,
    );
    final tempDir = await getTemporaryDirectory();
    final file = File(
        '${tempDir.path}/iqra_share_${DateTime.now().millisecondsSinceEpoch}.png');
    await file.writeAsBytes(await card.toPng());
    return file;
  }

  static Future<void> image({
    required BuildContext context,
    required ThemeProvider bloc,
    required String title,
    required String arabicTitle,
    required String arabicText,
    required String translationText,
    String? translatorName,
    String? paraNumber,
    String? surahNumber,
    String? ayatNumber,
  }) {
    final surahId = int.tryParse(surahNumber ?? '');
    final ayah = int.tryParse(ayatNumber ?? '');
    final hasRecitation = surahId != null && ayah != null && ayah > 0;
    return SharePreview.show(
      context,
      theme: bloc.selectedTheme,
      makeImage: (watermark) => _generateImage(
        bloc: bloc,
        title: title,
        arabicTitle: arabicTitle,
        arabicText: arabicText,
        translationText: translationText,
        translatorName: translatorName,
        paraNumber: paraNumber,
        surahNumber: surahNumber,
        ayatNumber: ayatNumber,
        watermark: watermark,
      ),
      makeVideo: hasRecitation
          ? (watermark, onProgress) => VerseVideo.create(
                bloc: bloc,
                title: title,
                arabicTitle: arabicTitle,
                arabicText: arabicText,
                translationText: translationText,
                translatorName: translatorName,
                paraNumber: paraNumber,
                surahId: surahId,
                ayahNumber: ayah,
                watermark: watermark,
                onProgress: onProgress,
              )
          : null,
      videoDescription: 'The video shows this verse with its recitation, '
          'each word highlighted as it is recited.',
    );
  }

  static void text({
    required String title,
    required String arabicText,
    required String translationText,
    String? surahNumber,
    String? ayatNumber,
  }) {
    Share.share(SharePreview.shareText);
  }
}
