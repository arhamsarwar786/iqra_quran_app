import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Screens/MainPage/Quran/Favorite.dart';
import 'package:iqra/Screens/MainPage/Quran/Quran.dart';
import 'package:iqra/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Utils/constants.dart';
import 'Quranview.dart';

class Surah extends StatefulWidget {
  const Surah({Key? key}) : super(key: key);

  @override
  State<Surah> createState() => _SurahState();
}

class _SurahState extends State<Surah> {
  QuranFavorite quranFavorite = QuranFavorite();
  List<int> numberofayat = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: FutureBuilder(
            future: DefaultAssetBundle.of(context).loadString(
                "assets/quran_kareem/urdu_translation/quranmetadata.json"),
            builder: (context, snapshot) {
              var qdata = json.decode(snapshot.data.toString());
              if (snapshot.hasData) {
                for (int i = 0; i < 114; i++) {
                  numberofayat.add(int.parse(
                    qdata["quran"]["suras"]["sura"][i]["ayas"],
                  ));
                }
                print(numberofayat.length);
              }

              return (snapshot.hasData)
                  ? ListView.builder(
                      itemCount: 114,
                      itemBuilder: (context, index) {
                        return Card(
                          elevation: 5,
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12)),
                            child: InkWell(
                              onTap: () {
                                // Navigator.push(
                                //     context,
                                //     MaterialPageRoute(
                                //         builder: (context) => QuranView(
                                //               ayatInSura: numberofayat,
                                //               ayatCount: qdata["quran"]["suras"]
                                //                   ["sura"][index]["ayas"],
                                //               surahCount: qdata["quran"]
                                //                       ["suras"]["sura"][index]
                                //                   ["index"],
                                //               surahName: qdata["quran"]["suras"]
                                //                   ["sura"][index]["name"],
                                //             )));
                              },
                              child: ListTile(
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) => QuranView(
                                                ayatInSura: numberofayat,
                                                ayatCount: qdata["quran"]
                                                        ["suras"]["sura"][index]
                                                    ["ayas"],
                                                surahCount: qdata["quran"]
                                                        ["suras"]["sura"][index]
                                                    ["index"],
                                                surahName: qdata["quran"]
                                                        ["suras"]["sura"][index]
                                                    ["name"],
                                              )));
                                },
                                title: Text(
                                  qdata["quran"]["suras"]["sura"][index]
                                      ["tname"],
                                  // "Ali",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                subtitle: Text(
                                  "${qdata["quran"]["suras"]["sura"][index]["type"]}-Verses:${qdata["quran"]["suras"]["sura"][index]["ayas"]}",
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                leading: CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Color(0xff005d66),
                                  child: Center(
                                      child: Text(
                                    qdata["quran"]["suras"]["sura"][index]
                                        ["index"],
                                    // "5",
                                    style: TextStyle(color: Colors.white),
                                  )),
                                ),
                                trailing: FittedBox(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        qdata["quran"]["suras"]["sura"][index]
                                            ["name"],
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () async {
                                          // print(numberofayat);
                                          quranFavorite = QuranFavorite(
                                            suratName: qdata["quran"]["suras"]
                                                ["sura"][index]["tname"],
                                            urduSuratName: qdata["quran"]
                                                    ["suras"]["sura"][index]
                                                ["name"],
                                            suraVerses: qdata["quran"]["suras"]
                                                ["sura"][index]["ayas"],
                                            // ayatInSura: numberofayat,
                                            surahCount: qdata["quran"]["suras"]
                                                ["sura"][index]["index"],
                                          );
                                          var list = QuranFavorite.fromJson(
                                              quranFavorite.toJson());
                                          int isFound = 0;
                                          List<QuranFavorite> fav = [];

                                          var getFav =
                                              await SavedPreferences.getFav()
                                                  .then((value) {
                                            return value;
                                            // fav=  quranFavoriteFromJson(
                                            //     jsonEncode(value));
                                          });
                                          if (getFav != null) {
                                            fav = quranFavoriteFromJson(
                                                jsonEncode(getFav));
                                            for (var items in fav) {
                                              if (items.suratName ==
                                                  list.suratName) {
                                                isFound = 1;
                                                print("enter loop $isFound");
                                              }
                                            }
                                            if (isFound == 0) {
                                              fav.add(list);
                                              SavedPreferences.setFav(fav);
                                              snackBar(context,
                                                  "Addes to Favourite successfully");
                                            } else {
                                              snackBar(context,
                                                  "Already added in favourite");
                                            }
                                          } else {
                                            List<QuranFavorite> addFav = [];
                                            print("new addes");
                                            addFav.add(list);
                                            SavedPreferences.setFav(addFav);
                                            snackBar(
                                                context, "Successfully added");
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.star_border_outlined,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: CircularProgressIndicator(
                        color: primayColor,
                      ),
                    );
            }));
  }
}
