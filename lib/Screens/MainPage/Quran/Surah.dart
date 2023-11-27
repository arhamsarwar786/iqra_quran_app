import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:iqra/Helper/favourite.dart';
import 'package:iqra/Models/quaran_favorate.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/Favorite.dart';
import 'package:iqra/Screens/MainPage/Quran/Quran.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../Models/aya_list_model.dart';
import '../../../Models/ruko_model.dart';
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
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Padding(
          padding: const EdgeInsets.all(12.0),
          child: FutureBuilder(
              future: DefaultAssetBundle.of(context)
                  .loadString("assets/extraction/quran-devsinn.json"),
              builder: (context, snapshot) {
                // var qdata = json.decode(snapshot.data.toString());
                // if (snapshot.hasData) {
                // for (int i = 0; i < 114; i++) {
                //   numberofayat.add(int.parse(
                //     qdata["quran"]["suras"]["sura"][i]["ayas"],
                //   ));
                // }
                // }

                if (snapshot.hasData && snapshot.data != null) {
                  var data = jsonDecode(snapshot.data.toString());
                  print(data!["sura"].length);
                  return ListView.builder(
                    itemCount: data!["sura"].length,
                    itemBuilder: (context, index) {
                      return Card(
                        elevation: 5,
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            onTap: () {
                              AyaListModel  ayatList = AyaListModel.fromJson(data["sura"][index]);
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => QuranView(
                                            ayat: ayatList.aya,
                                            suratNumber: index + 1,
                                            ayatCount: ayatList.aya.length.toString(),
                                            surahName: data["sura"][index]["name"],
                                          )));
                            },
                            title: Text(
                              data!["sura"][index]["name"],
                              // "Ali",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            // subtitle: qdata["quran"]["suras"]["sura"][index]["type"] == "Meccan" ?  Row(
                            //   children: [
                            //     Image.asset("assets/images/kabla${bloc.iconNumber}.png",height: 20,),
                            //     SizedBox(width: 10,),
                            //     Text(qdata["quran"]["suras"]["sura"][index]["ayas"])
                            //   ],
                            // ) : Row(
                            //   children: [
                            //     Image.asset("assets/images/masjid${bloc.iconNumber}.png",height: 20,),
                            //     SizedBox(width: 10,),

                            //     Text(qdata["quran"]["suras"]["sura"][index]["ayas"])
                            //   ],
                            // ),
                            leading: CircleAvatar(
                              radius: 15,
                              backgroundColor: bloc.selectedTheme,
                              child: Center(
                                  child: Text(
                                (index + 1).toString(),
                                // "5",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              )),
                            ),
                            trailing: FittedBox(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    data["sura"][index]["name"],
                                    style: TextStyle(
                                      fontFamily: bloc.urduFontFamily,
                                      color: Colors.black,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      // print(numberofayat);
                                      // quranFavorite = QuranFavorite(
                                      //   suratName: qdata["quran"]["suras"]
                                      //       ["sura"][index]["tname"],
                                      //   urduSuratName: qdata["quran"]
                                      //           ["suras"]["sura"][index]
                                      //       ["name"],
                                      //   suraVerses: qdata["quran"]["suras"]
                                      //       ["sura"][index]["ayas"],
                                      //   // ayatInSura: numberofayat,
                                      //   surahCount: qdata["quran"]["suras"]
                                      //       ["sura"][index]["index"],
                                      // );
                                      // var list = QuranFavorite.fromJson(
                                      //     quranFavorite.toJson());
                                      // int isFound = 0;
                                      // List<QuranFavorite> fav = [];

                                      // var getFav =
                                      //     await SavedPreferences.getFav()
                                      //         .then((value) {
                                      //   return value;
                                      //   // fav=  quranFavoriteFromJson(
                                      //   //     jsonEncode(value));
                                      // });
                                      // if (getFav != null) {
                                      //   fav = quranFavoriteFromJson(
                                      //       jsonEncode(getFav));
                                      //   for (var items in fav) {
                                      //     if (items.suratName ==
                                      //         list.suratName) {
                                      //       isFound = 1;
                                      //       print("enter loop $isFound");
                                      //     }
                                      //   }
                                      //   if (isFound == 0) {
                                      //     fav.add(list);
                                      //     SavedPreferences.setFav(fav);
                                      //     snackBar(context,
                                      //         "Addes to Favourite successfully");
                                      //   } else {
                                      //     snackBar(context,
                                      //         "Already added in favourite");
                                      //   }
                                      // } else {
                                      //   List<QuranFavorite> addFav = [];
                                      //   print("new addes");
                                      //   addFav.add(list);
                                      //   SavedPreferences.setFav(addFav);
                                      //   snackBar(
                                      //       context, "Successfully added");
                                      // }
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
                      );
                    },
                   
                  );
                }

                return Center(
                  child: CircularProgressIndicator(
                    color: Theme.of(context).primaryColor,
                  ),
                );
              }));
    });
  }
}
