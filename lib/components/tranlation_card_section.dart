import "package:flutter/material.dart";
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Utils/bottom_sheet_preview.dart';
import 'package:iqra/Utils/share_verse.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Models/surah_metadata_model.dart';
import '../Provider/theme_provider.dart';

class TranlationCardSection extends StatelessWidget {
  final ThemeProvider provider;
  final List<Aya> ayats;
  final int index;

  const TranlationCardSection({
    super.key,
    required this.provider,
    required this.ayats,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final aya = ayats[index];
    final quranProvider =
        Provider.of<QuranDataProvider>(context, listen: false);
    final int surahId = int.tryParse(aya.surahId ?? "1") ?? 1;
    final SurahMetadata? surah = quranProvider.getSurahMetadata(surahId);

    String translationText = "";
    String translatorName = "";

    if (provider.selectedTranslation == "irfan") {
      translationText = aya.tarjumaIrfan ?? "";
      translatorName = "عرفان القرآن";
    } else {
      translationText = aya.tarjumaPak ?? "";
      translatorName = "کنز الایمان";
    }

    return GestureDetector(
      onTap: () {
        SHEET.bottomSheetPreview(context, ayats, index, provider);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: provider.selectedTheme.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: provider.selectedTheme.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: provider.selectedTheme.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Verse ${aya.surahId}:${aya.ayatNumber}",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: provider.selectedTheme,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppShare.image(
                      context: context,
                      bloc: provider,
                      title: surah?.tname ?? "Surah",
                      arabicTitle: surah?.name ?? "",
                      arabicText: aya.arabicText,
                      translationText: translationText,
                      translatorName: translatorName,
                      paraNumber: aya.paraId,
                      surahNumber: aya.surahId,
                      ayatNumber: aya.ayatNumber,
                    );
                  },
                  icon: Icon(Icons.share_outlined,
                      color: provider.selectedTheme, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              aya.arabicText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: provider.arabicFontSize - 4,
                fontFamily: provider.arabicFontFamily,
                color: Colors.black,
                height: 1.6,
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 15),
              child: Divider(thickness: 0.5),
            ),
            Text(
              translatorName,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: provider.selectedTheme,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              translationText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: provider.urduFontSize - 5,
                fontFamily: provider.urduFontFamily,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
