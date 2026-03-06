import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'Quranview.dart';

class Surah extends StatefulWidget {
  const Surah({Key? key}) : super(key: key);

  @override
  State<Surah> createState() => _SurahState();
}

class _SurahState extends State<Surah> {
  List<QuranFavorite> favList = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final data = await SavedPreferences.getFav();
    if (data != null) {
      if (mounted) {
        setState(() {
          favList = quranFavoriteFromJson(jsonEncode(data));
        });
      }
    }
  }

  Future<void> _toggleFavorite(QuranFavorite fav) async {
    final index = favList.indexWhere((element) =>
        element.surahCount.toString() == fav.surahCount.toString() &&
        element.isPara != true);

    setState(() {
      if (index != -1) {
        favList.removeAt(index);
      } else {
        favList.add(fav);
      }
    });
    await SavedPreferences.setFav(favList);
  }

  bool _isFavorite(String surahCount) {
    return favList.any((element) =>
        element.surahCount.toString() == surahCount && element.isPara != true);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var themeProvider = context.read<ThemeProvider>();

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Consumer<QuranDataProvider>(
          builder: (context, quranProvider, child) {
            if (quranProvider.isLoading || !quranProvider.isLoaded) {
              return Center(
                child: CircularProgressIndicator(
                  color: themeProvider.selectedTheme,
                ),
              );
            }

            var surahMetadata = quranProvider.surahMetadata;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.builder(
                itemCount: surahMetadata.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.9,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                padding: const EdgeInsets.only(bottom: 20),
                itemBuilder: (context, index) {
                  var surah = surahMetadata[index];
                  int surahNumber = int.tryParse(surah.index) ?? (index + 1);

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuranView(
                            suratNumber: surahNumber,
                            ayatCount: surah.ayas,
                            surahName: surah.name,
                          ),
                        ),
                      );
                    },
                    child: Card(
                      color: themeProvider.selectedSecondary,
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Container(
                        padding: EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8.0, top: 4),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor:
                                        themeProvider.selectedTheme,
                                    child: Center(
                                        child: Text(
                                      surah.index,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 10),
                                    )),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 8.0, top: 6),
                                  child: Image.asset(
                                    surah.type == 'Meccan'
                                        ? 'assets/images/kaaba.png'
                                        : 'assets/images/madni.png',
                                    width: surah.type != 'Meccan' ? 35 : 24,
                                    height: surah.type != 'Meccan' ? 35 : 24,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                FittedBox(
                                  child: Text(
                                    surah.name,
                                    style: TextStyle(
                                        fontFamily:
                                            themeProvider.arabicFontFamily,
                                        color: Colors.black,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Ayat: ${surah.ayas}",
                                      style: TextStyle(
                                          fontFamily:
                                              themeProvider.arabicFontFamily,
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Ruku: ${surah.rukus}",
                                      style: TextStyle(
                                          fontFamily:
                                              themeProvider.arabicFontFamily,
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    )
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _toggleFavorite(QuranFavorite(
                                      suratName: surah.name,
                                      urduSuratName: "",
                                      suraVerses: surah.ayas,
                                      surahCount: surah.index,
                                      isPara: false,
                                    ));
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        right: 4, bottom: 4),
                                    child: Icon(
                                      _isFavorite(surah.index)
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: _isFavorite(surah.index)
                                          ? themeProvider.selectedTheme
                                          : themeProvider.selectedTheme,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      );
    });
  }
}
