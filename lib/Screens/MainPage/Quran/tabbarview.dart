// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

import '../../../widgets.dart';
import '../../../Helper/preference/saved_preferences.dart';
import 'Parah.dart';
import 'Quran.dart';
import 'Surah.dart';
import 'Quranview.dart';
import 'para_arabic_screen.dart';

class TabBarDemo extends StatelessWidget {
  const TabBarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    var themeProvider = context.read<ThemeProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
              onPressed: () async {
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
                                      lastRead["scrollOffset"]?.toDouble(),
                                )));
                  } else if (lastRead["type"] == "para") {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ParaArabicScreen(
                                  parahCount: lastRead["id"].toString(),
                                  parahname: lastRead["name"],
                                  ayatInPara:
                                      int.tryParse(lastRead["count"] ?? "0"),
                                  initialScrollOffset:
                                      lastRead["scrollOffset"]?.toDouble(),
                                )));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("No reading history found.")));
                }
              },
              backgroundColor: Colors.white,
              child: Container(
                height: 45,
                width: 45,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage("assets/images/book.png"),
                        fit: BoxFit.cover)),
              )),
          appBar: mainScreenAppBarPush(context, "Recite Quran"),
          body: DefaultTabController(
            length: 3,
            child: Column(
              children: <Widget>[
                Container(
                  constraints: BoxConstraints(maxHeight: 170.0),
                  child: Material(
                    color: themeProvider.selectedTheme,
                    child: TabBar(
                      labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: themeProvider.selectedSecondary,
                          fontSize: 14),
                      labelColor: themeProvider.selectedSecondary,
                      unselectedLabelColor: themeProvider.selectedSecondary,
                      indicatorColor: themeProvider.selectedSecondary,
                      unselectedLabelStyle: TextStyle(
                          fontWeight: FontWeight.normal,
                          color: themeProvider.selectedSecondary,
                          fontSize: 14),
                      indicatorPadding:
                          EdgeInsets.only(left: 10, right: 10, bottom: 5),
                      tabs: const [
                        Tab(
                          text: "Quran",
                        ),
                        Tab(
                          text: "Surah",
                        ),
                        Tab(
                          text: "Parah",
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                            // color: Theme.of(context).primaryColor,
                            // color: Color(0xffCC7180),
                            // borderRadius: BorderRadius.only(
                            //   topRight: Radius.circular(40),
                            //   topLeft: Radius.circular(40),
                            // ),
                            ),
                      ),
                      Container(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage("assets/images/BgImage.png")),
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(40),
                            topLeft: Radius.circular(40),
                          ),
                        ),
                        child: TabBarView(
                          children: const [
                            Quran(),
                            Surah(),
                            Parah(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
