import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:provider/provider.dart';

import '../../../widgets.dart';
import '../../../Helper/preference/saved_preferences.dart';
import 'Favorite.dart';
import 'Quranview.dart';

class Quran extends StatefulWidget {
  const Quran({Key? key}) : super(key: key);

  @override
  State<Quran> createState() => _QuranState();
}

class _QuranState extends State<Quran> {
  List<String> data = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Builder(builder: (context) {
            var bloc = context.read<ThemeProvider>();
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                  color: bloc.selectedSecondary,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.21,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: InkWell(
                      onTap: () async {
                        var lastRead = await SavedPrefernces.getLastRead();
                        if (lastRead != null) {
                          if (lastRead["type"] == "surah") {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => QuranView(
                                          suratNumber: lastRead["id"],
                                          surahName: lastRead["name"],
                                          ayatCount: lastRead["count"],
                                          initialScrollOffset:
                                              lastRead["scrollOffset"]
                                                  ?.toDouble(),
                                        )));
                          } else if (lastRead["type"] == "para") {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ParaArabicScreen(
                                          parahCount: lastRead["id"].toString(),
                                          parahname: lastRead["name"],
                                          ayatInPara: int.tryParse(
                                              lastRead["count"] ?? "0"),
                                          initialScrollOffset:
                                              lastRead["scrollOffset"]
                                                  ?.toDouble(),
                                        )));
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("No reading history found.")));
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.10,
                            width: MediaQuery.of(context).size.width * 0.20,
                            child: Image.asset(
                                "assets/images/namaz${int.parse(bloc.iconNumber)}.png"),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Last Read",
                            style: TextStyle(
                                color: bloc.selectedTheme,
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  color: bloc.selectedSecondary,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.21,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      // color: Colors.black12,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 10,
                          width: MediaQuery.of(context).size.width * 0.20,
                          child: Icon(Icons.list,
                              size: 70, color: bloc.selectedTheme),
                        ),
                        Text(
                          "Translation of Quran",
                          style: TextStyle(
                              color: bloc.selectedTheme,
                              fontSize: 17,
                              fontWeight: FontWeight.w600),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Card(
                  color: bloc.selectedSecondary,
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.21,
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      // color: Colors.black12,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: InkWell(
                      onTap: () {
                        push(context, const Favorite());
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.10,
                            width: MediaQuery.of(context).size.width * 0.20,
                            child: Icon(Icons.favorite_border,
                                size: 70, color: bloc.selectedTheme),
                          ),
                          Text(
                            "Favorite",
                            style: TextStyle(
                                color: bloc.selectedTheme,
                                fontSize: 17,
                                fontWeight: FontWeight.w600),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ));
  }
}
