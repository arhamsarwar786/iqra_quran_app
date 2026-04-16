import 'package:flutter/material.dart';
import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:provider/provider.dart';

class VerseDetailScreen extends StatelessWidget {
  final Aya aya;
  final SurahMetadata? surahMetadata;
  final String? searchQuery;

  const VerseDetailScreen({
    super.key,
    required this.aya,
    this.surahMetadata,
    this.searchQuery,
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
                  SelectableText.rich(
                    TextSpan(
                      children: _getHighlightSpans(
                        aya.arabicText,
                        searchQuery ?? '',
                        TextStyle(
                          fontSize: bloc.arabicFontSize + 2,
                          fontFamily: bloc.arabicFontFamily,
                          color: Colors.white,
                          height: 1.8,
                        ),
                        // Soft highlight color for white text on dark primary bg
                        Colors.black.withOpacity(0.3),
                        Colors.amberAccent,
                      ),
                    ),
                    textAlign: TextAlign.center,
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
                    context: context,
                    title: "Translation ($translatorName)",
                    content: translationText,
                    fontFamily: bloc.urduFontFamily,
                    fontSize: bloc.urduFontSize,
                    color: bloc.selectedTheme,
                  ),
                  const SizedBox(height: 20),
                  _detailCard(
                    context: context,
                    title: "Tafseer",
                    content: aya.withoutHtmlTafseer?.trim().isNotEmpty == true
                        ? aya.withoutHtmlTafseer!.trim()
                        : "Tafseer not available for this verse.",
                    fontFamily: bloc.urduFontFamily,
                    fontSize: bloc.urduFontSize - 2,
                    color: Colors.blueGrey[800]!,
                    isTafseer: true,
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
    required BuildContext context,
    required String title,
    required String content,
    required String fontFamily,
    required double fontSize,
    required Color color,
    bool isTafseer = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0, bottom: 8.0, right: 8.0),
          child: Text(
            title,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20), // Increased for better framing
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
            border: Border.all(color: color.withOpacity(0.05), width: 1),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: isTafseer
                ? _buildFormattedUrduText(
                    content,
                    fontFamily: fontFamily,
                    fontSize: fontSize,
                    themeColor: color,
                  )
                : SelectableText.rich(
                    TextSpan(
                      children: _getHighlightSpans(
                        content,
                        searchQuery ?? '',
                        TextStyle(
                          fontSize: fontSize,
                          fontFamily: fontFamily,
                          height: 1.8, // Increased for readability
                          color: Colors.black.withOpacity(0.85),
                        ),
                        color.withOpacity(0.2), // bg
                        color,                  // fg
                      ),
                    ),
                    textAlign: TextAlign.right,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormattedUrduText(
    String text, {
    required String fontFamily,
    required double fontSize,
    required Color themeColor,
  }) {
    final List<TextSpan> spans = [];

    // Aggressive Normalization: Flatten and clean input
    String cleanedText = text
        .replaceAll('\r', '')
        .replaceAll(RegExp(r'\n+'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();

    final RegExp exp = RegExp(
      r'\{(.*?)\}|\[(.*?)\]|\((.*?)\)|([^\{\[\]\(\)]+)',
      dotAll: true,
    );

    final Iterable<RegExpMatch> matches = exp.allMatches(cleanedText);

    for (final RegExpMatch match in matches) {
      if (match.group(1) != null) {
        // --- {Verse Highlight} ---
        // Ensure separation from previous text and clear space after
        spans.add(
          TextSpan(
            text: "\n{${match.group(1)!.trim()}}\n\n",
            style: TextStyle(
              color: themeColor,
              fontWeight: FontWeight.w900,
              fontSize: fontSize + 2.5,
              height: 1.95,
              fontFamily: fontFamily,
            ),
          ),
        );
      } else if (match.group(2) != null) {
        // --- [Topic Heading] ---
        // Double-break before and after for "Easy" readability
        spans.add(
          TextSpan(
            text: "\n\n[${match.group(2)!.trim()}]\n\n",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: fontSize + 1,
              height: 2.1,
              decoration: TextDecoration.underline,
              decorationColor: themeColor.withOpacity(0.35),
            ),
          ),
        );
      } else if (match.group(3) != null) {
        // --- (Footnote) ---
        spans.add(
          TextSpan(
            text: " (${match.group(3)!.trim()}) ",
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: (fontSize - 5.5).clamp(10.0, 18.0),
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
        );
      } else if (match.group(4) != null) {
        // --- Normal Body Text ---
        String body = match.group(4)!;
        if (body.trim().isEmpty) continue;

        spans.addAll(_getHighlightSpans(
          body,
          searchQuery ?? '',
          TextStyle(
            color: Colors.black.withOpacity(0.85),
            fontWeight: FontWeight.normal,
            fontSize: fontSize,
            height: 1.85,
          ),
          themeColor.withOpacity(0.2),
          themeColor,
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      textAlign: TextAlign.right,
      style: TextStyle(fontFamily: fontFamily),
    );
  }

  List<TextSpan> _getHighlightSpans(String text, String query, TextStyle style,
      Color highlightBgColor, Color highlightFgColor) {
    if (query.trim().isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    final String cleanQuery = QuranDataProvider.normalizeArabic(query).trim();
    if (cleanQuery.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    List<TextSpan> spans = [];
    int start = 0;

    // FIRST PASS: Literal case-insensitive match (for Urdu/English)
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    int literalIdx = lowerText.indexOf(lowerQuery);

    if (literalIdx != -1) {
      while (true) {
        final int index = lowerText.indexOf(lowerQuery, start);
        if (index < 0) {
          spans.add(TextSpan(text: text.substring(start), style: style));
          break;
        }
        if (index > start) {
          spans.add(TextSpan(text: text.substring(start, index), style: style));
        }
        spans.add(TextSpan(
          text: text.substring(index, index + lowerQuery.length),
          style: style.copyWith(
            backgroundColor: highlightBgColor,
            color: highlightFgColor,
            fontWeight: FontWeight.bold,
          ),
        ));
        start = index + lowerQuery.length;
      }
      return spans;
    }

    // SECOND PASS: Arabic Regex Match
    String diacritics =
        r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u06DF-\u06E4\u06E7-\u06E8\u06EA-\u06EB]*';
    StringBuffer regexBuf = StringBuffer();
    for (int i = 0; i < cleanQuery.length; i++) {
      String char = cleanQuery[i];
      if (r'\.^$*+?-()[]{}\|'.contains(char)) {
        regexBuf.write('\\$char');
      } else {
        regexBuf.write(char);
      }
      regexBuf.write(diacritics);
    }

    RegExp regex;
    try {
      regex = RegExp(regexBuf.toString(), caseSensitive: false);
    } catch (_) {
      regex = RegExp(RegExp.escape(cleanQuery), caseSensitive: false);
    }

    spans = [];
    start = 0;

    final matches = regex.allMatches(text);
    if (matches.isEmpty) {
      return [TextSpan(text: text, style: style)];
    }

    for (final match in matches) {
      if (match.start > start) {
        spans.add(TextSpan(text: text.substring(start, match.start), style: style));
      }
      spans.add(TextSpan(
        text: text.substring(match.start, match.end),
        style: style.copyWith(
          backgroundColor: highlightBgColor,
          color: highlightFgColor,
          fontWeight: FontWeight.bold,
        ),
      ));
      start = match.end;
    }
    if (start < text.length) {
      spans.add(TextSpan(text: text.substring(start), style: style));
    }
    return spans;
  }
}
