import 'package:flutter/material.dart';
import 'package:iqra/Models/para_metadata_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:provider/provider.dart';

enum QuranIndexSearchType { surah, para }

class QuranIndexSearchDelegate extends SearchDelegate<void> {
  QuranIndexSearchDelegate({required this.searchType});

  final QuranIndexSearchType searchType;

  @override
  String get searchFieldLabel => searchType == QuranIndexSearchType.surah
      ? 'Search Surah (Arabic, Urdu, English)'
      : 'Search Para (Arabic or number)';

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

  static String _toArabicDigits(String input) {
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return input.replaceAllMapped(
      RegExp(r'[0-9]'),
      (m) => arabic[int.parse(m.group(0)!)],
    );
  }

  bool _matchesQuery(String query, List<String?> fields) {
    final q = query.trim();
    if (q.isEmpty) return false;
    final qLower = q.toLowerCase();
    final qArabicDigits = _toArabicDigits(q);

    for (final field in fields) {
      if (field == null || field.isEmpty) continue;
      if (field.contains(q) ||
          field.toLowerCase().contains(qLower) ||
          field.contains(qArabicDigits)) {
        return true;
      }
    }
    return false;
  }

  List<SurahMetadata> _filterSurahs(String query, List<SurahMetadata> all) {
    if (query.trim().isEmpty) return [];
    return all.where((s) {
      return _matchesQuery(query, [
        s.surahId.toString(),
        s.surahName,
        s.romanName,
        s.romanEngName,
        s.searchSurahName,
        s.searchSurahNo,
        s.tname,
        s.ename,
      ]);
    }).toList();
  }

  List<ParaMetadata> _filterParas(String query, List<ParaMetadata> all) {
    if (query.trim().isEmpty) return [];
    return all.where((p) {
      return _matchesQuery(query, [
        p.paraId?.toString(),
        p.paraName,
        p.searchParaName,
        p.searchParaNo,
      ]);
    }).toList();
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
                ? 'Search by Arabic name, Urdu transliteration, or English name'
                : 'Search by Arabic para name or number (1–30)',
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
            '${surah.romanName}  •  ${surah.romanEngName}',
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
          subtitle: Text('Para $paraNumber  •  $ayatCount Ayat'),
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
