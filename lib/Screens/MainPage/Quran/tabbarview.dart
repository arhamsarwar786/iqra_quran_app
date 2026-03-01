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
  Future<void> _handleLastRead(BuildContext context) async {
    final lastRead = await SavedPrefernces.getLastRead();

    if (lastRead == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No reading history found.")),
      );
      return;
    }

    final type = lastRead["type"];
    final id = lastRead["id"];
    final name = lastRead["name"];
    final count = lastRead["count"];
    final scrollOffset = (lastRead["scrollOffset"] as num?)?.toDouble();

    Widget? destination;

    if (type == "surah") {
      destination = QuranView(
        suratNumber: id,
        surahName: name,
        ayatCount: count,
        initialScrollOffset: scrollOffset,
      );
    } else if (type == "para") {
      destination = ParaArabicScreen(
        parahCount: id.toString(),
        parahname: name,
        ayatInPara: int.tryParse(count?.toString() ?? "0"),
        initialScrollOffset: scrollOffset,
      );
    }

    if (destination != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => destination!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = context.read<ThemeProvider>();

    return SafeArea(
      child: Scaffold(
        floatingActionButton: FloatingActionButton.extended(
          foregroundColor: Colors.white,
          backgroundColor: themeProvider.selectedTheme,
          icon: const Icon(Icons.menu_book),
          label: const Text(
            "Last Read",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          onPressed: () => _handleLastRead(context),
        ),
        appBar: mainScreenAppBarPush(context, "Recite Quran"),
        body: DefaultTabController(
          length: 2,
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
                        children: [
                          const Surah(),
                          const Parah(),
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
    );
  }
}
