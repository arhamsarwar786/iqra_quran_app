// ignore_for_file: file_names

import 'dart:convert';
import 'dart:developer';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/translation/parah_translation_screen.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:provider/provider.dart';
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

  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;

  @override
  void initState() {
    super.initState();
    loadQuranMetaData();
    _scrollViewController = ScrollController();
    _scrollViewController!.addListener(() {
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = false;
          _showAppbar = true;
          setState(() {});
        }
      }

      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = true;
          _showAppbar = false;
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollViewController!.dispose();
    _scrollViewController!.removeListener(() {});
    super.dispose();
  }

  var qMetaData;
  loadQuranMetaData() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/quran_kareem/urdu_translation/quranmetadata.json");

    qMetaData = json.decode(data.toString());
    totalRuko = filterRuko(qMetaData['quran']['rukus']['ruku']);

    setState(() {});
  }

  List totalSurah = [], totalRuko = [];

  filterRuko(rukos) {
    List rukoFind = [];
    rukos.forEach((ruko) {
      if (widget.surahCount == ruko['sura']) {
        rukoFind.add(ruko);
      }
    });
    return rukoFind;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(child: Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: bloc.selectedTheme,
            items: [
              BottomNavigationBarItem(icon: InkWell(
                onTap: (){
                  push(context, ParahTranslationScreen());
                },
                child: Icon(Icons.book)),label: "Translation"),
              BottomNavigationBarItem(
                  icon: InkWell(
                      onTap: () {
                        var max =
                            _scrollViewController!.position.maxScrollExtent;
                        print(max);
                        double distance =
                            max - _scrollViewController!.position.pixels;
                        double durationInSeconds = distance / 50;

                        _scrollViewController!.animateTo(
                            _scrollViewController!.position.maxScrollExtent,
                            duration:
                                Duration(seconds: durationInSeconds.toInt()),
                            curve: Curves.linear);
                      },
                      child: Icon(Icons.fit_screen_outlined)),
                  label: "Auto Scrol"),
              BottomNavigationBarItem(
                  icon: Icon(Icons.settings), label: "Setting")
            ],
          ),
          //  appBar:customAppBar(context, "${widget.surahName}"),
          body: NestedScrollView(
            // controller: _scrollViewController,
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: bloc.selectedTheme,
                  expandedHeight: 160.0,
                  floating: false,
                  pinned: true,
                  snap: false,
                  toolbarHeight: 150,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    title: Container(
                      margin: EdgeInsets.only(top: 0),
                      // color: Colors.blueAccent,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Image.asset(
                                    "assets/images/borderLeft${int.parse(bloc.iconNumber) + 2}.png"),
                              ),
                              Expanded(
                                child: Image.asset(
                                    "assets/images/borderRight${int.parse(bloc.iconNumber) + 2}.png"),
                              ),
                            ],
                          ),
                          Text(
                            "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ",
                            style: MyTextStyle.heading2.copyWith(
                                color: Colors.white,
                                fontFamily: bloc.arabicFontFamily),
                          )
                        ],
                      ),
                    ),
                    background: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        AnimatedContainer(
                          height: _showAppbar ? 56.0 : 0.0,
                          duration: Duration(milliseconds: 200),
                          child: AppBar(
                            centerTitle: true,
                            iconTheme: IconThemeData(
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.white,
                            title: Text(
                              '${widget.surahName}',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: bloc.urduFontFamily,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // SliverPersistentHeader(

                //     pinned: true,
                //   ),
              ];
            },
            body: FutureBuilder(
                future: DefaultAssetBundle.of(context).loadString(
                    "assets/quran_kareem/urdu_translation/quran.json"),
                builder: (context, AsyncSnapshot snapshot) {
                  var quran = json.decode(snapshot.data.toString());
                  // totalRuko.clear();
                  // if (snapshot.hasData) {
                  //   var a = 0;
                  //   for (int i = 0; i <= 113; i++) {
                  //     dataSura.add(quran["quran"]["sura"][i]["name"]);
                  //     a = a + widget.ayatInSura![i];

                  //     for (int j = 1; j <= widget.ayatInSura![i]; j++) {
                  //       data.add(
                  //         quran["quran"]["sura"][i]["aya"][j - 1]["text"],
                  //       );
                  //     }
                  //   }
                  // }
                  if (snapshot.hasData) {
                    for (var i = 0; i < totalRuko.length; i++) {
                      // print(i);
                      if (totalRuko.length > i + 1) {
                        var current = int.parse(totalRuko[i]['aya']);
                        var next = int.parse(totalRuko[i + 1]['aya']);
                        // var finalAya = next - current;
                        // print(finalAya);

                        var ayaForRuko = "";
                        for (var index = current - 1; index < next; index++) {
                          ayaForRuko +=
                              "${quran["quran"]["sura"][int.parse(widget.surahCount.toString()) - 1]["aya"][index]["text"]} (${arabicNumber.convert(index + 1)})";
                        }
                        totalSurah.add(ayaForRuko);
                      } else {
                        print(widget.ayatCount);
                        var ayaForRuko = "";
                        for (var index = 0;
                            index < int.parse(widget.ayatCount.toString());
                            index++) {
                          ayaForRuko +=
                              "${quran["quran"]["sura"][int.parse(widget.surahCount.toString()) - 1]["aya"][index]["text"]} (${arabicNumber.convert(index + 1)})";
                        }
                        totalSurah.add(ayaForRuko);
                      }
                    }
                  }

                  // for (var index = 0; index < qMetaData['quran']['rukus']['ruku'].length ; index++) {
                  //   var ruko = qMetaData['quran']['rukus']['ruku'][index];
                  // if(ruko['sura'] == widget.surahCount){

                  //   print(widget.surahCount);
                  //   if(ruko['aya'] == "1" && qMetaData['quran']['rukus']['ruku'][index + 1]['sura'] != ruko['sura'] ){
                  //       var totalAyat = "";
                  //     for (var i = 1; i < int.parse(widget.ayatCount!); i++) {
                  //   totalAyat +=
                  //       "${quran["quran"]["sura"][int.parse(widget.surahCount.toString()) - 1]["aya"][i]["text"]} (${arabicNumber.convert(i)})";
                  //       // print(totalAyat);
                  //   }
                  //   totalSurah.add(totalAyat);
                  // // var totalAyat = "";
                  //   // totalAyat +=
                  //   //     "${quran["quran"]["sura"][int.parse(widget.surahCount.toString()) - 1]["aya"][i]["text"]} (${arabicNumber.convert(i)})";
                  //   //     print(totalAyat);
                  //   // totalSurah.add(totalAyat);
                  //   }else{
                  //       var totalAyat = "";

                  // for (var i = 1; i < int.parse(ruko['aya']); i++) {
                  //   totalAyat +=
                  //       "${quran["quran"]["sura"][int.parse(widget.surahCount.toString()) - 1]["aya"][i]["text"]} (${arabicNumber.convert(i)})";
                  //       // print(totalAyat);
                  //   }
                  //   totalSurah.add(totalAyat);
                  // }

                  // }

                  //     \n ${quran["sura"][int.parse(
                  //     widget.surahCount.toString()) -
                  // 1]["aya"][i]["text"]}" ;

                  // }
                  return Container(
                      padding: EdgeInsets.all(10),
                      // height: size.height / 1.75,
                      child: (snapshot.hasData)
                          ? SingleChildScrollView(
                              controller: _scrollViewController,
                              child: Column(
                                children: [
                                  ListView.builder(
                                      // controller: _scrollViewController,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      shrinkWrap: true,
                                      itemCount: totalSurah.length,
                                      itemBuilder: (context, index) {
                                        return Column(
                                          children: [
                                            Text(
                                              totalSurah[index],
                                              // " (" +
                                              // arabicNumber.convert(index) +
                                              // ")",
                                              textAlign: TextAlign.right,
                                              style: TextStyle(
                                                  // letterSpacing: 2,
                                                  fontFamily:
                                                      bloc.arabicFontFamily,
                                                  color: Colors.black,
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            Row(
                                              // mainAxisAlignment: MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                    child: Image.asset(
                                                        "assets/images/borderLeft${bloc.iconNumber}.png")),
                                                Text(
                                                  "ع",
                                                  style: MyTextStyle.heading1
                                                      .copyWith(
                                                          fontSize: 70,
                                                          fontFamily: bloc
                                                              .arabicFontFamily),
                                                ),
                                                Expanded(
                                                    child: Image.asset(
                                                        "assets/images/borderRight${bloc.iconNumber}.png")),
                                              ],
                                            )
                                          ],
                                        );
                                      }),

                                  //   Wrap(
                                  //     // crossAxisAlignment: CrossAxisAlignment.end,
                                  //     children: [
                                  // // for (int index = 0;
                                  // //     index < int.parse(widget.ayatCount.toString());
                                  // //     index++)
                                  //       Text(
                                  //         totalAyat,
                                  //             // " (" +
                                  //             // arabicNumber.convert(index) +
                                  //             // ")",
                                  //         textAlign: TextAlign.right,
                                  //         style: TextStyle(
                                  //             fontFamily: bloc.arabicFontFamily,
                                  //             color: Colors.black,
                                  //             fontSize: 30,
                                  //             fontWeight: FontWeight.w600),
                                  //       ),
                                  //       for(int index = 0; index < int.parse(widget.ayatCount.toString()); index++)

                                  //       Text(
                                  //         // "Ali",
                                  //         quran["sura"][int.parse(
                                  //                 widget.surahCount.toString()) -
                                  //             1]["aya"][index]["text"],
                                  //         textAlign: TextAlign.right,
                                  //         style: TextStyle(
                                  //             fontFamily: bloc.urduFontFamily,
                                  //             color: Colors.black,
                                  //             fontSize: 15,
                                  //             fontWeight: FontWeight.w400),
                                  //       ),
                                  //     ],
                                  //   )
                                ],
                              ),
                            )

                          // ?   ListView.builder(
                          //     itemCount: int.parse(widget.ayatCount.toString()),
                          //     itemBuilder: (context, index) {
                          //       return Wrap(children: [
                          //         Column(children: [
                          //           Text(
                          //               quran["quran"]["sura"][int.parse(
                          //                           widget.surahCount.toString()) -
                          //                       1]["aya"][index]["text"] +
                          //                   " (" +
                          //                   arabicNumber.convert(index) +
                          //                   ")",
                          //               textAlign: TextAlign.right,
                          //               style: TextStyle(
                          //                 fontFamily: bloc.arabicFontFamily,
                          //                   color: Colors.black,
                          //                   fontSize: 30,
                          //                   fontWeight: FontWeight.w600),
                          //             ),
                          //             Text(
                          //               // "Ali",
                          //               quran["sura"][int.parse(
                          //                       widget.surahCount.toString()) -
                          //                   1]["aya"][index]["text"],
                          //               textAlign: TextAlign.right,
                          //               style: TextStyle(
                          //                 fontFamily: bloc.urduFontFamily,
                          //                   color: Colors.black,
                          //                   fontSize: 15,
                          //                   fontWeight: FontWeight.w400),
                          //             ),

                          //         ],)
                          //       ],);

                          //     })
                          : Center(
                              child: CircularProgressIndicator(
                              color: Color.fromRGBO(255, 255, 255, 1),
                            )));
                }),
          ));
    }));
    // )})
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return new Container(
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
