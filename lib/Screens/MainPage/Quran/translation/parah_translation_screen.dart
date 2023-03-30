import 'dart:convert';

import "package:flutter/material.dart";
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:provider/provider.dart';

import '../../../../components/tranlation_card_section.dart';

class ParahTranslationScreen extends StatefulWidget {
  ParahTranslationScreen(
      {super.key, this.ayatInSura, this.parahCount, this.parahname});
  final String? parahCount;
  List<int>? ayatInSura;
  final String? parahname;

  @override
  State<ParahTranslationScreen> createState() => _ParahTranslationScreenState();
}

class _ParahTranslationScreenState extends State<ParahTranslationScreen> {
  List<int> num = [
    0,
    148 + 2,
    111 + 0,
    125 + 1,
    132 + 1,
    124 + 0,
    111 + 1,
    148 + 1,
    142 + 1,
    159 + 1,
    128 + 1,
    150 + 2,
    170 + 1,
    155 + 3,
    227 + 1,
    184 + 2,
    269 + 2,
    190 + 2,
    202 + 3,
    343 + 2,
    166 + 2,
    179 + 4,
    163 + 3,
    363 + 3,
    175 + 2,
    247 + 4,
    194 + 6,
    400 + 6,
    137 + 9,
    430 + 11,
    564 + 37,
  ];
  List<String> data = [];
  List<int> prevriousSuraIndex = [];
  List<String> urdudata = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Builder(builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Scaffold(
          appBar: PreferredSize(
              preferredSize: Size.fromHeight(100.0),
              child: AppBar(
                centerTitle: true,
                title: Text("Translation"),
                backgroundColor: Color.fromARGB(255, 170, 170, 170),
                bottom: PreferredSize(
                  child: Container(
                    height: 50,
                    color: bloc.selectedTheme,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: Text(
                      "PARA NAME",
                      style: MyTextStyle.heading3
                          .copyWith(color: MyColors.whiteColor),
                    ),
                  ),
                  preferredSize: Size.fromHeight(50),
                ),
              )),
          body: FutureBuilder(
              future: DefaultAssetBundle.of(context).loadString(
                  "assets/quran_kareem/urdu_translation/quran.json"),
              builder: (context, snapshot) {
                var quran = json.decode(snapshot.data.toString());
                if (snapshot.hasData) {
                  var a = 0;
                  for (int i = 0; i < num.length; i++) {
                    a = a + num[i];
                    prevriousSuraIndex.add(a);
                  }
                  for (int i = 0; i <= 113; i++) {
                    data.add(
                      quran["quran"]["sura"][i]["name"],
                    );
                    urdudata.add(" ");
                    a = a + widget.ayatInSura![i];

                    for (int j = 1; j <= widget.ayatInSura![i]; j++) {
                      data.add(
                        quran["quran"]["sura"][i]["aya"][j - 1]["text"],
                      );
                      urdudata.add(
                        quran["sura"][i]["aya"][j - 1]["text"],
                      );
                    }
                  }
                }
                return ListView.builder(
                    itemCount: num[(int.parse(widget.parahCount.toString()))],
                    itemBuilder: (context, i) {
                      return TranlationCardSection(
                        provider: bloc,
                        arabic: (data[(i +
                            prevriousSuraIndex[
                                (int.parse(widget.parahCount.toString())) -
                                    1])]),
                        urdu: urdudata[(i +
                            prevriousSuraIndex[
                                (int.parse(widget.parahCount.toString())) -
                                    1])],
                      );
                    });
              }),
        );
      }),
    );
  }
}
