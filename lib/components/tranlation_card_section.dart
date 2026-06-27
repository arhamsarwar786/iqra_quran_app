import "package:flutter/material.dart";
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Utils/bottom_sheet_preview.dart';
import 'package:iqra/Utils/share_verse.dart';
import 'package:iqra/Utils/utils.dart';
import 'package:iqra/Screens/MainPage/Quran/verse_detail_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Models/surah_metadata_model.dart';
import '../Provider/theme_provider.dart';

class TranlationCardSection extends StatelessWidget {
  final ThemeProvider provider;
  final List<Aya> ayats;
  final int index;
  final bool isHighlighted;

  const TranlationCardSection({
    super.key,
    required this.provider,
    required this.ayats,
    required this.index,
    this.isHighlighted = false,
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
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: isHighlighted
                  ? provider.selectedTheme.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isHighlighted ? 15 : 10,
              offset: Offset(0, isHighlighted ? 6 : 4),
            ),
          ],
          border: Border.all(
            color: isHighlighted
                ? provider.selectedTheme
                : provider.selectedTheme.withOpacity(0.1),
            width: isHighlighted ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header Row ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      height: 30,
                      width: 30,
                      decoration: BoxDecoration(
                          color: provider.selectedTheme,
                          borderRadius: BorderRadius.circular(100),
                          image: DecorationImage(
                              image: AssetImage("assets/images/iqra-white.png"),
                              fit: BoxFit.fill)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      "QURAN",
                      style: TextStyle(
                        color: provider.selectedTheme,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // ── Tafseer Button ──────────────────────────
                      IconButton(
                        onPressed: () {
                          push(
                            context,
                            VerseDetailScreen(
                              aya: aya,
                              surahMetadata: surah,
                            ),
                          );
                        },
                        icon: Icon(Icons.menu_book_rounded,
                            color: provider.selectedTheme, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Tafseer',
                      ),
                      const SizedBox(width: 12),
                      // ── Share Button ────────────────────────────
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
                        icon: Icon(Icons.share,
                            color: provider.selectedTheme, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Share',
                      ),
                      const SizedBox(width: 20),
                      Flexible(
                        child: Text(
                          surah?.name ?? "",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: provider.selectedTheme,
                            fontSize: 20,
                            fontFamily: provider.arabicFontFamily,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Arabic Text ─────────────────────────────────────────
            Text(
              aya.arabicText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: provider.arabicFontSize,
                fontFamily: provider.arabicFontFamily,
                color: Colors.black,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 15),

            // ── Translation ─────────────────────────────────────────
            Text(
              translationText,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: provider.urduFontSize,
                fontFamily: provider.urduFontFamily,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // ── Source Pill ─────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    "Para: ${aya.paraId}  •  Surah: ${aya.surahId}  •  Verse: ${aya.ayatNumber}",
                    style: TextStyle(
                      color: provider.selectedTheme,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
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
