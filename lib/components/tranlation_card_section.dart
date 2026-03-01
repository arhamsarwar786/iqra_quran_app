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
      translatorName = "Kanz-ul-Irfan";
    } else {
      translationText = aya.tarjumaHind ?? "";
      translatorName = "Kanz-ul-Iman";
    }

    // Safety fallback: If selected translation is empty (e.g. Alif Lam Mim in Iman),
    // show the other one so the user isn't left with an empty card.
    if (translationText.trim().isEmpty) {
      translationText = aya.tarjumaIrfan ?? aya.tarjumaPak ?? "";
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
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
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
                color: provider.selectedTheme,
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
            const SizedBox(height: 15),
            // ── Source pill: Para · Surah · Verse numbers ──────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: provider.selectedTheme,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: provider.selectedTheme.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    "Para: ${aya.paraId}  •  Surah: ${aya.surahId}  •  Verse: ${aya.ayatNumber}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
