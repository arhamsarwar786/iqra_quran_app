// ignore_for_file: file_names

import 'dart:convert';

import 'package:flutter/material.dart';
import '../../../widgets.dart';

class PQuranView extends StatefulWidget {
  PQuranView({
    this.ayatInSura,
    this.parahCount,
    this.parahname,
  });
  final String? parahCount;
  List<int>? ayatInSura;
  final String? parahname;
  // final String? ayaCount;
  @override
  State<PQuranView> createState() => _PQuranViewState();
}

class _PQuranViewState extends State<PQuranView> {

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
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        appBar: customAppBar(context, "${widget.parahname}"),
        body: FutureBuilder(
            future: DefaultAssetBundle.of(context)
                .loadString("assets/quran_kareem/urdu_translation/quran.json"),
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
              return Container(
                  // height: size.height / 1.85,
                  child: (snapshot.hasData)
                      ? ListView.builder(
                          itemCount:
                              num[(int.parse(widget.parahCount.toString()))],
                          // itemCount: int.parse(_num[int.parse(
                          //         widget.parahCount.toString()) -
                          //     1]),
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 3,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10)),
                                child: ListTile(
                                  subtitle: Text(
                                    // "$index",
                                    urdudata[(index +
                                        prevriousSuraIndex[(int.parse(
                                                widget.parahCount.toString())) -
                                            1])],
                                    textAlign: TextAlign.right,

                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w400),
                                  ),
                                  title: Text(
                                    (data[(index +
                                        prevriousSuraIndex[(int.parse(
                                                widget.parahCount.toString())) -
                                            1])]),
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
                          color: Colors.black,
                        )));
            }));
  }
}
