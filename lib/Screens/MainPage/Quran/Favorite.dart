// ignore_for_file: file_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:provider/provider.dart';

import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> with SingleTickerProviderStateMixin {
  List<QuranFavorite> surahList = [];
  List<Aya> bookmarkedAyats = [];
  bool isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    // Load surah favourites
    final favData = await SavedPreferences.getFav();
    if (favData != null && mounted) {
      surahList = quranFavoriteFromJson(jsonEncode(favData));
    }

    // Load bookmarked ayats
    final bookmarkData = await SavedPreferences.getBookmarkedAyats();
    if (bookmarkData != null && mounted) {
      final provider = context.read<QuranDataProvider>();
      final Set<String> keys = Set<String>.from(bookmarkData);
      final List<Aya> resolved = [];
      for (final key in keys) {
        final parts = key.split('_');
        if (parts.length < 2) continue;
        final surahId = int.tryParse(parts[0]) ?? 0;
        final ayatNumber = parts[1];
        final ayats = provider.getAyatsBySurah(surahId);
        final match = ayats.where((a) => a.ayatNumber == ayatNumber).toList();
        if (match.isNotEmpty) resolved.add(match.first);
      }
      bookmarkedAyats = resolved;
    }

    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _removeBookmark(Aya aya) async {
    final key = "${aya.surahId}_${aya.ayatNumber}";
    final data = await SavedPreferences.getBookmarkedAyats();
    if (data != null) {
      final Set<String> keys = Set<String>.from(data);
      keys.remove(key);
      await SavedPreferences.setBookmarkedAyats(keys.toList());
    }
    setState(() => bookmarkedAyats.removeWhere(
        (a) => a.surahId == aya.surahId && a.ayatNumber == aya.ayatNumber));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final provider = context.read<QuranDataProvider>();

    return Scaffold(
      backgroundColor: theme.selectedSecondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: theme.selectedTheme, size: 24),
        ),
        centerTitle: true,
        title: Text(
          "Saved",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: theme.selectedTheme,
            letterSpacing: 0.5,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: theme.selectedTheme,
          labelColor: theme.selectedTheme,
          unselectedLabelColor: Colors.grey[500],
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: "Surah"),
            Tab(text: "Bookmarked Ayat"),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(child: CircularProgressIndicator(color: theme.selectedTheme))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildSurahTab(theme),
                  _buildBookmarkedAyatTab(theme, provider),
                ],
              ),
      ),
    );
  }

  // ─── Tab 1: Surah Favourites ──────────────────────────────────────────────

  Widget _buildSurahTab(ThemeProvider theme) {
    if (surahList.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.bookmark_border_rounded,
        "No saved surahs",
        "Mark surahs as favourite to see them here",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      itemCount: surahList.length,
      itemBuilder: (context, index) {
        final data = surahList[index];
        final titleText = data.suratName ??
            (data.isPara == true ? "Unknown Para" : "Unknown Surah");

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.selectedTheme.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                if (data.isPara == true) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ParaArabicScreen(
                        para: null,
                        ayatInPara:
                            int.tryParse(data.suraVerses.toString()) ?? 0,
                        parahCount: data.surahCount.toString(),
                        parahname: data.suratName,
                        saveLastRead: false,
                      ),
                    ),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => QuranView(
                        suratNumber:
                            int.tryParse(data.surahCount.toString()) ?? 1,
                        surahName: data.suratName,
                        ayatCount: data.suraVerses.toString(),
                        saveLastRead: false,
                      ),
                    ),
                  );
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    // Index circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.selectedTheme.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: theme.selectedTheme.withOpacity(0.3),
                            width: 1),
                      ),
                      child: Center(
                        child: Text(
                          (index + 1).toString(),
                          style: TextStyle(
                            color: theme.selectedTheme,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titleText,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                              fontFamily: theme.arabicFontFamily,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                data.isPara == true
                                    ? Icons.menu_book
                                    : Icons.format_list_numbered,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                data.isPara == true
                                    ? "Ayat: ${data.suraVerses}"
                                    : "Verses: ${data.suraVerses}",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (data.urduSuratName != null &&
                            data.urduSuratName.toString().trim().isNotEmpty) ...[
                          Text(
                            data.urduSuratName.toString(),
                            style: TextStyle(
                              fontFamily: theme.arabicFontFamily,
                              fontSize: 18,
                              color: theme.selectedTheme,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () async {
                            setState(() => surahList.removeAt(index));
                            await SavedPreferences.setFav(surahList);
                          },
                          icon: Icon(Icons.favorite,
                              color: theme.selectedTheme, size: 26),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Tab 2: Bookmarked Ayats ──────────────────────────────────────────────

  Widget _buildBookmarkedAyatTab(
      ThemeProvider theme, QuranDataProvider provider) {
    if (bookmarkedAyats.isEmpty) {
      return _buildEmptyState(
        theme,
        Icons.turned_in_not_rounded,
        "No bookmarked ayat",
        "Tap the verse number circle to bookmark an ayat",
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      itemCount: bookmarkedAyats.length,
      itemBuilder: (context, index) {
        final aya = bookmarkedAyats[index];
        final surahId = int.tryParse(aya.surahId ?? '0') ?? 0;
        final SurahMetadata? meta = provider.getSurahMetadata(surahId);
        final String surahName = meta?.surahName ?? "Surah $surahId";
        final String surahRoman = meta?.romanName ?? '';
        final int ayatNum = aya.ayatNumberInt;

        // Clean Arabic text preview
        String preview = aya.arabicText.trim();
        preview = preview.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '');
        if (preview.length > 80) preview = "${preview.substring(0, 80)}…";

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.selectedTheme.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                // Navigate to QuranView at that ayat — saveLastRead: false
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => QuranView(
                      suratNumber: surahId,
                      surahName: surahName,
                      ayatCount: meta?.surahTotalAyaat.toString(),
                      targetAyatNumber: ayatNum,
                      saveLastRead: false, // ← does NOT affect last read
                    ),
                  ),
                );
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Verse number circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: theme.selectedTheme.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: theme.selectedTheme.withOpacity(0.4),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          ayatNum.toString(),
                          style: TextStyle(
                            color: theme.selectedTheme,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Surah name header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (surahRoman.isNotEmpty) ...[
                                  Text(
                                    surahRoman,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: theme.arabicFontFamily,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.selectedTheme.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  surahName,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: theme.selectedTheme,
                                    fontFamily: theme.arabicFontFamily,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Arabic text preview
                          Text(
                            preview,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: theme.arabicFontFamily,
                              color: Colors.black87,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Remove bookmark button
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _removeBookmark(aya),
                      icon: Icon(Icons.turned_in_rounded,
                          color: theme.selectedTheme, size: 24),
                      tooltip: "Remove bookmark",
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyState(
      ThemeProvider theme, IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.selectedTheme.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60,
                color: theme.selectedTheme.withOpacity(0.5)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: theme.selectedTheme.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
