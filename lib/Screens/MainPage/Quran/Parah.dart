import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';

class Parah extends StatefulWidget {
  const Parah({Key? key}) : super(key: key);

  @override
  State<Parah> createState() => _ParahState();
}

class _ParahState extends State<Parah> {
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
        element.isPara == true);

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
        element.surahCount.toString() == surahCount && element.isPara == true);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var bloc = context.watch<ThemeProvider>();
      return Padding(
        padding:
            const EdgeInsets.only(left: 8.0, right: 8.0, top: 15, bottom: 10),
        child: Consumer<QuranDataProvider>(
          builder: (context, quranProvider, child) {
            if (quranProvider.isLoading || !quranProvider.isLoaded) {
              return Center(
                  child: CircularProgressIndicator(color: bloc.selectedTheme));
            }

            // Use para metadata from provider
            var paraMetadata = quranProvider.paraMetadata;

            return Directionality(
              textDirection: TextDirection.rtl,
              child: GridView.builder(
                itemCount: paraMetadata.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1, // 2/2 is 1
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  var paraItem = paraMetadata[index];
                  int paraNumber = paraItem.paraId ?? 0;
                  int ayatCount =
                      quranProvider.paraAyatCounts[paraNumber.toString()] ?? 0;
                  int rukuCount =
                      quranProvider.paraRukuCounts[paraNumber.toString()] ?? 0;
                  String paraName = paraItem.paraName ?? 'Para $paraNumber';

                  return InkWell(
                    onTap: () {
                      push(
                          context,
                          ParaArabicScreen(
                            para: null,
                            ayatInPara: ayatCount,
                            parahCount: paraNumber.toString(),
                            parahname: paraName,
                          ));
                    },
                    child: Card(
                      color: bloc.selectedSecondary,
                      elevation: 5,
                      child: Container(
                        padding: EdgeInsets.all(5),
                        // height: MediaQuery.of(context).size.height * 0.22,
                        // width: MediaQuery.of(context).size.height * 0.22,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(left: 8.0, top: 2),
                                  child: CircleAvatar(
                                    radius: 12,
                                    backgroundColor: bloc.selectedTheme,
                                    child: Center(
                                        child: Text(
                                      (index + 1).toString(),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        paraName,
                                        style: TextStyle(
                                            fontFamily: bloc.arabicFontFamily,
                                            color: Colors.black,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Ayat: $ayatCount",
                                      style: TextStyle(
                                          fontFamily: bloc.arabicFontFamily,
                                          color: Colors.black,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      "Ruku: $rukuCount",
                                      style: TextStyle(
                                          fontFamily: bloc.arabicFontFamily,
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
                              children: [],
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

// quran.juzs.juz[0].aya

// ,
//           {
//             "isPart": true,
//             "Surat": 2,
//             "Place":"الربع",
//             "arabic": null,
//             "translation1": null,
//             "translation2": null,
//             "ayatNumber": null
//           },
