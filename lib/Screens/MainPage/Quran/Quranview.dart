// ignore_for_file: file_names

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
// import 'arabic';
import '../../../widgets.dart';

class QuranView extends StatefulWidget {
  QuranView({this.ayatInSura, this.ayatCount, this.surahCount, this.surahName});
  final String? ayatCount;
  List<int>? ayatInSura;
  final String? surahCount;
  final String? surahName;
  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  List<String> data = [];
  List<String> dataSura = [];
  List<int> count = [0, 7, 141];
  List<int> num = [
    148,
    111,
    126,
    131,
    124,
    110,
    149,
    142,
    159,
    127,
    151,
    170,
    154,
    227,
    185,
    269,
    190,
    202,
    339,
    171,
    178,
    169,
    357,
    175,
    246,
    195,
    399,
    137,
    431,
    564,
  ];
  List<int> ayatcount = [
    7,
    286,
    200,
    176,
    120,
    165,
    206,
    75,
    129,
    109,
    123,
    111,
    43,
    52,
    99,
    128,
    111,
    110,
    98,
    135,
    112,
    78,
    118,
    64,
    77,
    227,
    93,
    88,
    69,
    60,
    34,
    30,
    73,
    54,
    45,
    83,
    182,
    88,
    75,
    85,
    54,
    53,
    89,
    59,
    37,
    35,
    38,
    29,
    18,
    45,
    60,
    49,
    62,
    55,
    78,
    96,
    29,
    22,
    24,
    13,
    14,
    11,
    11,
    18,
    12,
    12,
    30,
    52,
    52,
    44,
    28,
    28,
    20,
    56,
    40,
    31,
    50,
    40,
    46,
    42,
    29,
    19,
    36,
    25,
    22,
    17,
    19,
    26,
    30,
    20,
    15,
    21,
    11,
    8,
    8,
    19,
    5,
    8,
    8,
    11,
    11,
    8,
    3,
    9,
    5,
    4,
    7,
    3,
    6,
    3,
    5,
    4,
    5,
    6
  ];
  ArabicNumbers arabicNumber = ArabicNumbers();
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: customAppBar(context, "${widget.surahName}"),
        body: FutureBuilder(
            future: DefaultAssetBundle.of(context)
                .loadString("assets/quran_kareem/urdu_translation/quran.json"),
            builder: (context, snapshot) {
              var quran = json.decode(snapshot.data.toString());

              if (snapshot.hasData) {
                var a = 0;
                for (int i = 0; i <= 113; i++) {
                  dataSura.add(quran["quran"]["sura"][i]["name"]);
                  a = a + widget.ayatInSura![i];

                  for (int j = 1; j <= widget.ayatInSura![i]; j++) {
                    data.add(
                      quran["quran"]["sura"][i]["aya"][j - 1]["text"],
                    );
                  }
                }
              }

              return Container(
                  // height: size.height / 1.75,
                  child: (snapshot.hasData)
                      ? ListView.builder(
                          itemCount: int.parse(widget.ayatCount.toString()),
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  subtitle: Text(
                                    // "Ali",
                                    quran["sura"][int.parse(
                                            widget.surahCount.toString()) -
                                        1]["aya"][index]["text"],
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  title: Text(
                                    quran["quran"]["sura"][int.parse(
                                                widget.surahCount.toString()) -
                                            1]["aya"][index]["text"] +
                                        " (" +
                                        arabicNumber.convert(index) +
                                        ")",
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                            );
                          })
                      : Center(
                          child: CircularProgressIndicator(
                          color: Color.fromRGBO(255, 255, 255, 1),
                        )));
            }));
  }
}
