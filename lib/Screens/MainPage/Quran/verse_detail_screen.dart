import 'package:flutter/material.dart';
import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class VerseDetailScreen extends StatelessWidget {
  final Aya aya;
  final SurahMetadata? surahMetadata;

  const VerseDetailScreen({
    super.key,
    required this.aya,
    this.surahMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<ThemeProvider>(context);

    String translationText = "";
    String translatorName = "";

    if (bloc.selectedTranslation == "irfan") {
      translationText = aya.tarjumaIrfan ?? "";
      translatorName = "Kanz-ul-Irfan";
    } else {
      translationText = aya.tarjumaHind ?? "";
      translatorName = "Kanz-ul-Iman";
    }

    if (translationText.trim().isEmpty) {
      translationText = aya.tarjumaIrfan ?? aya.tarjumaPak ?? "";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surahMetadata?.tname ?? "Verse Detail",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              "Ayat ${aya.ayatNumber}",
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        backgroundColor: bloc.selectedTheme,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              decoration: BoxDecoration(
                color: bloc.selectedTheme,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    aya.arabicText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: bloc.arabicFontSize + 2,
                      fontFamily: bloc.arabicFontFamily,
                      color: Colors.white,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Para ${aya.paraId}  •  Surah ${aya.surahId}  •  Verse ${aya.ayatNumber}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detailCard(
                    title: "Translation ($translatorName)",
                    content: translationText,
                    fontFamily: bloc.urduFontFamily,
                    fontSize: bloc.urduFontSize,
                    color: bloc.selectedTheme,
                  ),
                  const SizedBox(height: 20),
                  _detailCard(
                    title: "Tafseer",
                    content: aya.withoutHtmlTafseer?.trim().isNotEmpty == true
                        ? aya.withoutHtmlTafseer!.trim()
                        : "Tafseer not available for this verse.",
                    fontFamily: bloc.urduFontFamily,
                    fontSize: bloc.urduFontSize - 2,
                    color: Colors.blueGrey[800]!,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _detailCard({
    required String title,
    required String content,
    required String fontFamily,
    required double fontSize,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            content,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: fontSize,
              fontFamily: fontFamily,
              height: 1.6,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
