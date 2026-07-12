import 'package:flutter/material.dart';
import 'package:iqra/Models/para_metadata_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:provider/provider.dart';

enum QuranIndexSearchType { surah, para }

/// Common English / Urdu aliases for the 30 paras (South Asian naming).
const Map<int, List<String>> _paraAliases = {
  1: ['Alif Lam Meem', 'Alif Laam Meem', 'الم', 'الف لام میم', 'Para 1', 'Juz 1'],
  2: ['Sayaqool', 'Sayakul', 'سیقول', 'سیاقول', 'Para 2', 'Juz 2'],
  3: ['Tilkal Rusul', 'Tilkar Rusul', 'تلک الرسل', 'Para 3', 'Juz 3'],
  4: ['Lan Tanaloo', 'Lan Tanaalu', 'لن تنالوا', 'Para 4', 'Juz 4'],
  5: ['Wal Mohsanat', 'Wal Muhsanat', 'والمحصنات', 'Para 5', 'Juz 5'],
  6: ['La Yuhibbullah', 'La Yuhibbullaha', 'لا يحب الله', 'لا یحب اللہ', 'Para 6', 'Juz 6'],
  7: ['Wa Iza Samiu', 'Wa Idha Samiu', 'واذا سمعوا', 'Para 7', 'Juz 7'],
  8: ['Wa Lau Annana', 'Walau Annana', 'ولو اننا', 'Para 8', 'Juz 8'],
  9: ['Qalal Mala', 'Qala al Mala', 'قال الملا', 'Para 9', 'Juz 9'],
  10: ['Wa Aalamu', 'Wa Alamoo', 'واعلموا', 'Para 10', 'Juz 10'],
  11: ['Yatazerun', 'Yaatazerun', 'يعتذرون', 'یعتذرون', 'Para 11', 'Juz 11'],
  12: ['Wa Ma Min Dabbah', 'Wama Min Dabbatin', 'وما من دابة', 'Para 12', 'Juz 12'],
  13: ['Wa Ma Ubrioo', 'Wama Ubri', 'وما ابرئ', 'Para 13', 'Juz 13'],
  14: ['Rubama', 'Rubama', 'ربما', 'Para 14', 'Juz 14'],
  15: ['Subhanallazi', 'Subhanalladhi', 'سبحان الذي', 'سبحان الذی', 'Para 15', 'Juz 15'],
  16: ['Qal Alam', 'Qala Alam', 'قال الم', 'Para 16', 'Juz 16'],
  17: ['Iqtaraba', 'Iqtaraba Linnas', 'اقترب', 'Para 17', 'Juz 17'],
  18: ['Qad Aflaha', 'قد افلح', 'Para 18', 'Juz 18'],
  19: ['Wa Qalallazina', 'Wa Qalalladhina', 'وقال الذين', 'Para 19', 'Juz 19'],
  20: ['Amman Khalaq', 'Aman Khalaq', 'امن خلق', 'Para 20', 'Juz 20'],
  21: ['Utlu Ma Oohi', 'Utlu Ma Uhiya', 'اتل ما اوحي', 'Para 21', 'Juz 21'],
  22: ['Wa Man Yaqnut', 'Waman Yaqnut', 'ومن يقنت', 'Para 22', 'Juz 22'],
  23: ['Wa Mali', 'Wama Li', 'وما لي', 'Para 23', 'Juz 23'],
  24: ['Faman Azlam', 'Faman Azlama', 'فمن اظلم', 'Para 24', 'Juz 24'],
  25: ['Ilaihi Yuraddu', 'Ilayhi Yuraddu', 'اليه يرد', 'Para 25', 'Juz 25'],
  26: ['Ha Meem', 'Ha Mim', 'حم', 'حا میم', 'Para 26', 'Juz 26'],
  27: ['Qala Fama Khatbukum', 'قال فما خطبكم', 'Para 27', 'Juz 27'],
  28: ['Qad Sami Allah', 'Qad SamiAllahu', 'قد سمع الله', 'قد سمع اللہ', 'Para 28', 'Juz 28'],
  29: ['Tabarakallazi', 'Tabarakalladhi', 'تبارك الذي', 'تبارک الذی', 'Para 29', 'Juz 29'],
  30: [
    'Amma Yatasaaloon',
    'Amma Yatasa\'aloon',
    'Amma',
    'عم',
    'عم یتساءلون',
    'Para 30',
    'Juz 30',
    'Sipara 30',
  ],
};

class QuranIndexSearchDelegate extends SearchDelegate<void> {
  QuranIndexSearchDelegate({required this.searchType});

  final QuranIndexSearchType searchType;

  @override
  String get searchFieldLabel => searchType == QuranIndexSearchType.surah
      ? 'Search Surah (Arabic, Urdu, English)'
      : 'Search Para (Arabic, Urdu, English)';

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: theme.selectedTheme,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.grey[500], fontSize: 15),
        border: InputBorder.none,
      ),
    );
  }

  /// Strip Arabic/Urdu diacritics and normalize similar letters for search.
  static String _normalizeArabic(String input) {
    var s = input;
    // Remove tatweel + common Quranic diacritics / marks
    s = s.replaceAll(RegExp(r'[\u064B-\u065F\u0670\u06D6-\u06ED\u0640]'), '');
    // Normalize alef variants → ا
    s = s.replaceAll(RegExp(r'[أإآٱ]'), 'ا');
    // Normalize yeh / alef maksura
    s = s.replaceAll('ى', 'ي');
    s = s.replaceAll('ی', 'ي'); // Urdu yeh → Arabic yeh
    // Normalize teh marbuta
    s = s.replaceAll('ة', 'ه');
    // Normalize kaf / waw variants used in Urdu
    s = s.replaceAll('ک', 'ك');
    s = s.replaceAll('ؤ', 'و');
    s = s.replaceAll('ئ', 'ي');
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), '');
    return s;
  }

  static String _normalizeLatin(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r"[^a-z0-9\s]"), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _toArabicDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => arabic[int.parse(m.group(0)!)],
    );
  }

  static String _toWesternDigits(String input) {
    const map = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
      '۰': '0',
      '۱': '1',
      '۲': '2',
      '۳': '3',
      '۴': '4',
      '۵': '5',
      '۶': '6',
      '۷': '7',
      '۸': '8',
      '۹': '9',
    };
    var s = input;
    map.forEach((k, v) => s = s.replaceAll(k, v));
    return s;
  }

  bool _fieldMatches(String query, String? field) {
    if (field == null || field.isEmpty) return false;

    final qRaw = query.trim();
    final qLatin = _normalizeLatin(qRaw);
    final qArabic = _normalizeArabic(qRaw);
    final qWestern = _toWesternDigits(qRaw);
    final qArabicDigits = _toArabicDigits(qWestern);

    final fLatin = _normalizeLatin(field);
    final fArabic = _normalizeArabic(field);
    final fWestern = _toWesternDigits(field);

    if (qLatin.isNotEmpty && fLatin.contains(qLatin)) return true;
    if (qArabic.isNotEmpty && fArabic.contains(qArabic)) return true;
    if (fWestern.contains(qWestern)) return true;
    if (field.contains(qArabicDigits)) return true;
    if (field.toLowerCase().contains(qRaw.toLowerCase())) return true;
    return false;
  }

  bool _matchesAny(String query, List<String?> fields) {
    if (query.trim().isEmpty) return false;
    for (final field in fields) {
      if (_fieldMatches(query, field)) return true;
    }
    return false;
  }

  /// Prefer a single English display name (avoid "Al Fatihah • Al Fatiha").
  String _englishDisplayName(SurahMetadata s) {
    final a = s.romanEngName.trim();
    final b = s.romanName.trim();
    if (a.isEmpty) return b;
    if (b.isEmpty) return a;
    if (_normalizeLatin(a) == _normalizeLatin(b)) return a;
    // Prefer the shorter / cleaner eng name when they differ slightly
    return a;
  }

  List<SurahMetadata> _filterSurahs(String query, List<SurahMetadata> all) {
    if (query.trim().isEmpty) return [];
    return all.where((s) {
      return _matchesAny(query, [
        s.surahId.toString(),
        s.surahName,
        s.searchSurahName,
        s.searchSurahNo,
        s.romanName,
        s.romanEngName,
        s.romanUrl,
      ]);
    }).toList();
  }

  List<ParaMetadata> _filterParas(String query, List<ParaMetadata> all) {
    if (query.trim().isEmpty) return [];
    return all.where((p) {
      final id = p.paraId ?? 0;
      final aliases = _paraAliases[id] ?? const <String>[];
      return _matchesAny(query, [
        id.toString(),
        p.paraName,
        p.searchParaName,
        p.searchParaNo,
        ...aliases,
      ]);
    }).toList();
  }

  String _paraEnglishName(int paraId) {
    final aliases = _paraAliases[paraId];
    if (aliases == null || aliases.isEmpty) return 'Para $paraId';
    // First alias is the primary English name
    return aliases.first;
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    if (query.isEmpty) return null;
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final provider = context.watch<QuranDataProvider>();

    if (provider.isLoading || !provider.isLoaded) {
      return Center(
        child: CircularProgressIndicator(color: bloc.selectedTheme),
      );
    }

    if (query.trim().isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            searchType == QuranIndexSearchType.surah
                ? 'Search by Arabic, Urdu, or English name / number'
                : 'Search by Arabic, Urdu, English name / number (1–30)',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 15),
          ),
        ),
      );
    }

    if (searchType == QuranIndexSearchType.surah) {
      return _buildSurahResults(context, bloc, provider);
    }
    return _buildParaResults(context, bloc, provider);
  }

  Widget _buildSurahResults(
    BuildContext context,
    ThemeProvider bloc,
    QuranDataProvider provider,
  ) {
    final results = _filterSurahs(query, provider.surahMetadata);
    if (results.isEmpty) {
      return const Center(child: Text('No surah found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
      itemBuilder: (context, i) {
        final surah = results[i];
        final english = _englishDisplayName(surah);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: bloc.selectedTheme,
            child: Text(
              '${surah.surahId}',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          title: Text(
            surah.surahName,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: bloc.arabicFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            english,
            style: const TextStyle(fontSize: 13),
          ),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuranView(
                  suratNumber: surah.surahId,
                  ayatCount: surah.ayas,
                  surahName: surah.name,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildParaResults(
    BuildContext context,
    ThemeProvider bloc,
    QuranDataProvider provider,
  ) {
    final results = _filterParas(query, provider.paraMetadata);
    if (results.isEmpty) {
      return const Center(child: Text('No para found'));
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: results.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
      itemBuilder: (context, i) {
        final para = results[i];
        final paraNumber = para.paraId ?? 0;
        final ayatCount =
            provider.paraAyatCounts[paraNumber.toString()] ?? 0;
        final paraName = para.paraName ?? 'Para $paraNumber';
        final english = _paraEnglishName(paraNumber);

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: bloc.selectedTheme,
            child: Text(
              '$paraNumber',
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          title: Text(
            paraName,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: bloc.arabicFontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          subtitle: Text('$english  •  $ayatCount Ayat'),
          onTap: () {
            close(context, null);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ParaArabicScreen(
                  ayatInPara: ayatCount,
                  parahCount: paraNumber.toString(),
                  parahname: paraName,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

void showQuranIndexSearch(
  BuildContext context, {
  required QuranIndexSearchType searchType,
}) {
  showSearch<void>(
    context: context,
    delegate: QuranIndexSearchDelegate(searchType: searchType),
  );
}
