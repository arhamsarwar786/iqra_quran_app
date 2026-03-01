import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:provider/provider.dart';

import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class _FavoriteState extends State<Favorite> {
  List<QuranFavorite> list = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final data = await SavedPreferences.getFav();
    if (data != null && mounted) {
      setState(() {
        list = quranFavoriteFromJson(jsonEncode(data));
        isLoading = false;
      });
    } else if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor: themeProvider.selectedSecondary,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back,
              color: themeProvider.selectedTheme, size: 24),
        ),
        centerTitle: true,
        title: Text(
          "Favorites",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: themeProvider.selectedTheme,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(
                    color: themeProvider.selectedTheme))
            : list.isEmpty
                ? _buildEmptyState(themeProvider)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      var data = list[index];
                      String indexStr = (index + 1).toString();
                      String titleText = data.suratName ??
                          (data.isPara == true
                              ? "Unknown Para"
                              : "Unknown Surah");

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeProvider.selectedTheme.withOpacity(0.08),
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
                                      ayatInPara: int.tryParse(
                                              data.suraVerses.toString()) ??
                                          0,
                                      parahCount: data.surahCount.toString(),
                                      parahname: data.suratName,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => QuranView(
                                      suratNumber: int.tryParse(
                                              data.surahCount.toString()) ??
                                          1,
                                      surahName: data.suratName,
                                      ayatCount: data.suraVerses.toString(),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(
                                children: [
                                  // Number Icon
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: themeProvider.selectedTheme
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: themeProvider.selectedTheme
                                              .withOpacity(0.3),
                                          width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        indexStr,
                                        style: TextStyle(
                                          color: themeProvider.selectedTheme,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),

                                  // Titles and Details
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          titleText,
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                            fontFamily:
                                                themeProvider.arabicFontFamily,
                                          ),
                                          // Arabic text usually looks better with proper alignment
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

                                  // Trailing Heart
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (data.urduSuratName != null &&
                                          data.urduSuratName
                                              .toString()
                                              .trim()
                                              .isNotEmpty) ...[
                                        Text(
                                          data.urduSuratName.toString(),
                                          style: TextStyle(
                                            fontFamily:
                                                themeProvider.arabicFontFamily,
                                            fontSize: 18,
                                            color: themeProvider.selectedTheme,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        onPressed: () async {
                                          setState(() {
                                            list.removeAt(index);
                                          });
                                          await SavedPreferences.setFav(list);
                                        },
                                        icon: Icon(
                                          Icons.favorite,
                                          color: themeProvider.selectedTheme,
                                          size: 26,
                                        ),
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
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: themeProvider.selectedTheme.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.favorite_border_rounded,
              size: 60,
              color: themeProvider.selectedTheme.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No favorites yet",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: themeProvider.selectedTheme.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Mark surahs as favorite to see them here",
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
