// ignore_for_file: file_names

import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart'; // You have to add this manually, for some reason it cannot be added automatically
import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/translation/parah_translation_screen.dart';
import 'package:iqra/Screens/MainPage/Quran/translation/surah_translation_screen.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:provider/provider.dart';
// import 'arabic';
import '../../../Models/aya_list_model.dart';
import '../../../Models/ruko_model.dart';
import '../../../Models/sajda_model.dart';
import '../../../Utils/bottom_sheet_preview.dart';
import '../../../Utils/constants.dart';
import '../../../Utils/fs_system.dart';
import '../../../Utils/utils.dart';
import '../../../widgets.dart';

class QuranView extends StatefulWidget {
  QuranView({this.ayatCount, this.surahName, this.ayat, this.suratNumber});
  final String? ayatCount;
  int? suratNumber;
  List<Aya>? ayat;
  final String? surahName;
  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;

  Future<List<RukoModel>> getRuko() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/ruko.json");
    var rukoDataLocal = rukoModelFromJson(data);
    rukoData = rukoDataLocal
        .where((element) => element.surat == widget.suratNumber)
        .toList();
    return rukoData ?? [];
  }

  Future<List<SajdaModel>> getSajda() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/sajda.json");
    var sajdaDataLocal = sajdaModelFromJson(data);
    sajdaData = sajdaDataLocal
        .where((element) => element.surat == widget.suratNumber.toString())
        .toList();

    return sajdaData ?? [];
  }

  List<Widget> quranViewWidget = [];

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();
    List total = [];
    List<RukoModel> rukoList = await getRuko();
    // List<SajdaModel> sajdaList = await getSajda();
    // print(sajdaList.toString() + " total Sajda");
    for (var i = 0; i < rukoList.length; i++) {
      // debugger();
      int start = i > 0 ? rukoList[i - 1].ayaBeforeRako : 0;
      int next = rukoList[i].ayaAfterRako + 1;
      int ayaLength = widget.ayat!.length;
      // int start = i > 0 ? int.parse(rukoList[i - 1].ayaAfterRako)  : 0;
      // int next = start + int.parse(rukoList[i].diff);

      // if(rukoList[i - 1].surat != rukoList[i].surat){

      // }
      // debugger();
      print(
          "${start} ---- ${next} |--- length = ${widget.ayat!.length} -- total Ruko = ${rukoList.length}");
      var ayaList = widget.ayat!.sublist(start, next);
      // ayaLength > next ? ayaLength : next
      List<TextSpan> textSpanChildren = [];
      // if (sajdaList.isNotEmpty) {
      //   for (int l = 0; l < sajdaList.length ; l++) {
      //     var sajda = sajdaList[l];
      //     // print(sajda.ayaBeforeSajda);
      //     // print(ayaList);
      //     var index = ayaList.indexWhere((element) => int.parse(sajda.ayaBeforeSajda) == element.ayatNumber);
      //     print(index.toString() + " index here");
      //     if (index != -1) {
      //       var sajdaAyaList = ayaList.sublist(0, index);
      //       print(sajdaAyaList.length.toString() + " total sajda list is here");

      //       for (int k = 0; k < sajdaAyaList.length; k++) {
      //         var aya = sajdaAyaList[k];
      //         textSpanChildren.add(
      //           TextSpan(
      //             text: "${(aya.arabic).trim()} ",
      //             style: TextStyle(color: Colors.black),
      //             recognizer: TapGestureRecognizer()
      //               ..onTap = () {
      //                 print(i);
      //               },
      //           ),
      //         );
      //       }

      //       quranViewWidget.add(Stack(
      //         alignment: Alignment.center,
      //         children: [
      //           Text(
      //             "SAJDA",
      //             style: MyTextStyle.heading1.copyWith(
      //                 fontSize: 70, fontFamily: bloc.arabicFontFamily),
      //           ),
      //         ],
      //       ));
      //     }
      //   }

      //   for (int k = 0; k < ayaList.length; k++) {
      //     var aya = ayaList[k];
      //     SajdaModel? sajdaModel = isSajda(aya.ayatNumber, sajdaList);
      //     if (sajdaModel != null) {
      //       // print("${sajdaModel.toJson()} =--------= aya number = ${aya.ayatNumber} =--------= ${ aya.toJson()}");
      //     }
      //   }
      // } else {
        for (int k = 0; k < ayaList.length; k++) {
          var aya = ayaList[k];
          if(aya.sajda != null){
            // break;
           var newList = ayaList.sublist(k+1,ayaList.length);
           print(newList.length);
          //  debugger();
           textSpanChildren.add(
            TextSpan(
              text: "${(aya.arabic).trim()} ",
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print(i);
                  SHEET.bottomSheetPreview(context,aya,bloc);
                },
            ),
          );
             quranViewWidget.add(RichText(
        text: TextSpan(
          children: textSpanChildren,
          style: TextStyle(
              fontSize: bloc.arabicFontSize,
              fontFamily: bloc.arabicFontFamily,
              color: Colors.black
              // Add other styles as needed
              ),
        ),
      ));
      textSpanChildren = [];

          quranViewWidget.add(Stack(
        alignment: Alignment.center,
        children: [
          Text(
            aya.sajda!,
            style: MyTextStyle.heading1
                .copyWith(fontSize: 30, fontFamily: bloc.arabicFontFamily),
          ),
          
        ],
      ));

      for (var a in newList) {
        textSpanChildren.add(
            TextSpan(
              text: "${(a.arabic).trim()} ",
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print(i);
                  SHEET.bottomSheetPreview(context,aya,bloc);
                },
            ),
          );
      }
      break;

          }else{
          textSpanChildren.add(
            TextSpan(
              text: "${(aya.arabic).trim()} ",
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  print(i);
                  SHEET.bottomSheetPreview(context,aya,bloc);
                },
            ),
          );
          }
        }
      // }
      quranViewWidget.add(RichText(
        text: TextSpan(
          children: textSpanChildren,
          style: TextStyle(
              fontSize: bloc.arabicFontSize,
              fontFamily: bloc.arabicFontFamily,
              color: Colors.black
              // Add other styles as needed
              ),
        ),
      ));

      quranViewWidget.add(Stack(
        alignment: Alignment.center,
        children: [
          Text(
            "ع",
            style: MyTextStyle.heading1
                .copyWith(fontSize: 70, fontFamily: bloc.arabicFontFamily),
          ),
          Positioned(bottom: 30, child: Text(rukoList[i].diff.toString())),
          Positioned(top: 20, child: Text(rukoList[i].rakuNumber.toString())),
          Positioned(
              bottom: 0, child: Text(rukoList[i].bottomNumber.toString()))
        ],
      ));

      //  Expanded(
      //  child: Image.asset(
      //      "assets/images/borderRight${bloc.iconNumber}.png")),

      // quranViewWidget.add(Text(
      //    "ع",
      //   style: MyTextStyle.heading1.copyWith(
      //     fontSize: 70,
      //     fontFamily: bloc.arabicFontFamily,
      //   ),));
    }
    print(total);
    print(total.length);
    setState(() {});
    // debugger();
    // for (var i = 0; i < widget.ayat!.length ; i++) {
    // if(rukoList.isNotEmpty){
    //   for (var j = 0; j < rukoList.length; j++) {
    //   if(i == rukoList[j].ayaAfterRako){

    //   }else{

    //   }

    //   }
    // }
    // }
  }

  List<RukoModel>? rukoData;
  List<SajdaModel>? sajdaData;

  loadData() async {
    var bloc = context.read<ThemeProvider>();

    //  await getArabic();
    getRuko().then((ruko) {
      getSajda().then((sajda) {
        bismillaChecker();
        listTextSpan(bloc, ruko, sajda).then((val) {
          print(children.length);
          // debugger();
          if (val) {
            setState(() {});
          }
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    viewMaker();
    // loadData();
    _scrollViewController = ScrollController();
    _scrollViewController!.addListener(() {
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          _showAppbar = true;
          setState(() {});
        }
      }

      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          _showAppbar = false;
          setState(() {});
        }
      }
    });
  }

  bool isBismilla = true;

  bismillaChecker() {
    bool isAvailable = widget.ayat![0].arabic == bismillaArabic;
    if (!isAvailable) {
      setState(() {
        isBismilla = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollViewController!.dispose();
    _scrollViewController!.removeListener(() {});
    super.dispose();
  }

  isRuku(index, List<RukoModel> ruko) {
    var data = ruko.firstWhereOrNull(
        (element) => (element.ayaAfterRako == index.toString()));
    return data;
  }

  isSajda(index, List<SajdaModel> sajda) {
    var data = sajda.firstWhereOrNull(
        (element) => (element.ayaBeforeSajda == index.toString()));
    return data;
  }

  String arabicText = "";

  getArabic() {
    for (int index = 0;
        index < int.parse(widget.ayatCount.toString());
        index++) {
      arabicText += "${widget.ayat![index].arabic}${index == 0 ? '\n' : " "}";
    }
    setState(() {});
  }

  //   String arabicText = "";

  // getArabic(){
  //   for(int index = 0; index < int.parse(widget.ayatCount.toString()); index++){
  //     RukoModel rukoModel =  isRuku(index);
  //   arabicText += "${widget.ayat![index].arabic}".trim() + "${index == 0 ? '\n' : " "}" + "${rukoModel == null  ? "" : ""}";
  //   }
  //   setState(() {

  //   });
  // }

  List<TextSpan> children = [];

  listTextSpan(bloc, ruko, sajda) async {
    // debugger();
    for (int i = isBismilla ? 1 : 0; i < widget.ayat!.length; i++) {
      RukoModel? rukoModel = isRuku(i, ruko);
      SajdaModel? sajdaModel = isSajda(i, sajda);
      children.add(
        TextSpan(
          text: "${(widget.ayat![i].arabic).trim()} ",
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print(i);
            },
        ),
      );
      // debugger();
      if (rukoModel != null) {
        children.add(TextSpan(
          text: "\nع\n",
          style: MyTextStyle.heading1.copyWith(
            fontSize: 70,
            fontFamily: bloc.arabicFontFamily,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print(i);
              // debugger();
            },
        ));
      }
      if (sajdaModel != null) {
        children.add(TextSpan(
          text: "\n${sajdaModel.place}\n",
          style: MyTextStyle.heading1
              .copyWith(fontSize: 70, fontFamily: bloc.arabicFontFamily),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              print(i);
              // debugger();
            },
        ));
      }
      // setState(() {

      // });
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(child: Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {},
        //   child: Text(widget.ayat!.length.toString()),
        // ),
        bottomNavigationBar: isScrollingDown
            ? SizedBox()
            : BottomNavigationBar(
                backgroundColor: bloc.selectedTheme,
                items: [
                  BottomNavigationBarItem(
                      icon: InkWell(
                          onTap: () {
                            push(
                                context,
                                SurahTranslationScreen(
                                  ayatCount: widget.ayatCount.toString(),
                                  ayatList: widget.ayat,
                                  suratNumber: widget.suratNumber,
                                  surahName: widget.surahName,
                                ));
                          },
                          child: Icon(Icons.book)),
                      label: "Translation"),
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
                                duration: Duration(
                                    seconds: durationInSeconds.toInt()),
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
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
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
                                "assets/images/borderLeft1.png",
                                color: Color.fromARGB(255, 255, 109, 109),
                              ),
                            ),
                            Expanded(
                              child: Image.asset(
                                "assets/images/borderRight1.png",
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        if (isBismilla)
                          Text(
                            "${bismillaArabic}",
                            style: MyTextStyle.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: bloc.arabicFontFamily),
                          ),
                        SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Image.asset(
                                "assets/images/borderLeft1.png",
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: Image.asset(
                                "assets/images/borderRight1.png",
                                color: Color.fromARGB(255, 255, 109, 109),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  background: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedContainer(
                        height: _showAppbar ? 56.0 : 56.0,
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

          body:
              // children.isEmpty
              //     ? CircularProgressIndicator()
              //     :
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: DecorationImage(image: AssetImage("assets/images/border.png",),fit: BoxFit.fill, alignment: Alignment.topCenter)
                ),
                  // height: size.height / 1.75,
 padding: const EdgeInsets.only(left: 0, right: 0, top: 20, bottom: 20),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      controller: _scrollViewController,
                      child: Container(
                        margin: const EdgeInsets.only(left: 23, right: 30, top: 30, bottom: 30),
                        child: Column(
                          children: quranViewWidget,
                        ),
                      ),
                      // child: RichText(
                      //   text: TextSpan(
                      // //       style: TextStyle(
                      //           fontSize: bloc.arabicFontSize,
                      //           fontFamily: bloc.arabicFontFamily,
                      //           color: Colors.black
                      //           // Add other styles as needed
                      //           ),
                      //       children:
                      //           // [
                      //           //   ...widget.ayat!.mapIndexed((i, e) {
                      //           //     RukoModel? rukoModel = isRuku(i);
                      //           //     SajdaModel? sajdaModel = isSajda(i);
                      //           //     if (rukoData != null) {
                      //           //   return TextSpan(
                      //           //     text:
                      //           //         "ع",
                      //           //     style: rukoModel == null
                      //           //         ? TextStyle(
                      //           //             fontSize: bloc.arabicFontSize,
                      //           //             fontFamily: bloc.arabicFontFamily,
                      //           //             color: Colors.black
                      //           //             // Add other styles as needed
                      //           //             )
                      //           //         : MyTextStyle.heading1.copyWith(
                      //           //             fontSize: 70,
                      //           //             fontFamily: bloc.arabicFontFamily),
                      //           //     recognizer: TapGestureRecognizer()
                      //           //       ..onTap = () {
                      //           //         print(i);
                      //           //         // debugger();
                      //           //       },
                      //           //   );
                      //           // }
                      //           //     return TextSpan(
                      //           //       text:
                      //           //           "${(widget.ayat![i].arabic).trim()}",
                      //           //       style: rukoModel == null
                      //           //           ? TextStyle(
                      //           //               fontSize: bloc.arabicFontSize,
                      //           //               fontFamily: bloc.arabicFontFamily,
                      //           //               color: Colors.black
                      //           //               // Add other styles as needed
                      //           //               )
                      //           //           : MyTextStyle.heading1.copyWith(
                      //           //               fontSize: 70,
                      //           //               fontFamily: bloc.arabicFontFamily),
                      //           //       recognizer: TapGestureRecognizer()
                      //           //         ..onTap = () {
                      //           //           print(i);
                      //           //           // debugger();
                      //           //         },
                      //           //     );
                      //           //   })
                      //           // ]

                      //           children
                      //       // [
                      //       //   for (int i = isBismilla ? 1 : 0;
                      //       //       i < widget.ayat!.length;
                      //       //       i++)
                      //       //     TextSpan(
                      //       //       text: "${(widget.ayat![i].arabic).trim()} ",
                      //       //       recognizer: TapGestureRecognizer()
                      //       //         ..onTap = () {
                      //       //           print(i);
                      //       //           // debugger();
                      //       //         },
                      //       //     ),
                      //       // ],
                      //       ),
                      // ),
                    ),
                  )

                  // child: Directionality(
                  //  textDirection: TextDirection.rtl,
                  //  child: Wrap(children: [
                  //   Text("asdkasldkadkajkal"),
                  //   Text("asdkasldkadkajkal------"),
                  //   Text("as dka sldkadkajkal"),
                  //   Text("asdkasldkadkajkal"),
                  //   // Text("asdkasldkadkajkal"),
                  //  ],),
                  // ),

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
                  // quran["sura"][int.parse(
                  //         widget.surahCount.toString()) -
                  //     1]["aya"][index]["text"],
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
                  ),
        ),
      );
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

//              ListView.builder(
//                  // controller: _scrollViewController,
//                  physics:
//                      const NeverScrollableScrollPhysics(),
//                  shrinkWrap: true,
//                  itemCount: widget.ayat!.length,
//                  itemBuilder: (context, index) {
// RukoModel? rukoModel =  isRuku(index);
// SajdaModel? sajdaModel =  isSajda(index);
//                    return Column(
//                      children: [
//                       // Divider(),
//                       //  Divider(),
//                       //  Divider(),
//                        Text(
//                          widget.ayat![index].arabic.toString(),
//                          // " (" +
//                          // arabicNumber.convert(index) +
//                          // ")",
//                          textAlign: TextAlign.right,
//                          style: TextStyle(
//                            fontSize: bloc.arabicFontSize,fontFamily: bloc.arabicFontFamily,
//                           fontWeight: FontWeight.bold
//                              ),
//                        ),
//                       //  Divider(),
//                       //  Divider(),
//                       //  Divider(),
//                       //  Text("ترجمہ: کنزالایمان"),
//                       //   Text(
//                       //    widget.ayat![index].translation1.toString(),
//                       //    // " (" +
//                       //    // arabicNumber.convert(index) +
//                       //    // ")",
//                       //    textAlign: TextAlign.right,
//                       //    style: TextStyle(
//                       //      fontSize: bloc.urduFontSize,fontFamily: bloc.urduFontFamily,
//                       //     fontWeight: FontWeight.w500
//                       //        ),
//                       //  ),
//                       //  Divider(),
//                       //  Divider(),
//                       //  Divider(),
//                       //   Text(
//                       //    widget.ayat![index].translation2.toString(),
//                       //    // " (" +
//                       //    // arabicNumber.convert(index) +
//                       //    // ")",
//                       //    textAlign: TextAlign.right,
//                       //    style: TextStyle(
//                       //      fontSize: bloc.urduFontSize,fontFamily: bloc.urduFontFamily,
//                       //     fontWeight: FontWeight.w500
//                       //        ),
//                       //  ),

// Row(
// mainAxisSize: MainAxisSize.max,
// mainAxisAlignment: MainAxisAlignment.center,
//   children: [
//                        if(rukoModel != null )
//                        Row(
//                          // mainAxisAlignment: MainAxisAlignment.center,
//                          crossAxisAlignment:
//                              CrossAxisAlignment.center,
//                          children: [
//                           //  Expanded(
//                           //      child: Image.asset(
//                           //          "assets/images/borderLeft${bloc.iconNumber}.png")),
//      Stack(
//       alignment: Alignment.center,
//        children: [
//          Text(
//            "ع",
//            style: MyTextStyle.heading1
//                .copyWith(
//                    fontSize: 70,
//                    fontFamily: bloc
//                        .arabicFontFamily),
//          ),
//          Positioned(
//           bottom: 30,
//           child: Text(rukoModel.diff)),
//           Positioned(
//           top: 20,
//           child: Text(rukoModel.rakuNumber))
//        ],
//      ),

//     //  Expanded(
//         //  child: Image.asset(
//         //      "assets/images/borderRight${bloc.iconNumber}.png")),
//    ],
//  )
//                      ,
//                      if(sajdaModel != null )
//                      Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                        children: [
//                                                  if(sajdaModel.serial != null)
//                           Text(" (${sajdaModel.serial}) ", style: MyTextStyle.heading1
//                                          .copyWith(
//                                              fontSize: 20,
//                                              color: MyColors.greenColor,
//                                              fontFamily: bloc
//                                                  .arabicFontFamily),),
//                          Text(" ${sajdaModel.place} ", style: MyTextStyle.heading1
//                                          .copyWith(
//                                              fontSize: 20,
//                                              color: MyColors.greenColor,
//                                              fontFamily: bloc
//                                                  .arabicFontFamily),),

//                        ],
//                      )

// ],)
//                      ],
//                    );
//                  },
//                  ),

//                Wrap(
//                  children: [

// // bloc.arabicFontSize
//  Text(
//    arabicText,
//    textAlign: TextAlign.right,
//    style: MyTextStyle.heading3.copyWith(fontSize: bloc.arabicFontSize,fontFamily: bloc.arabicFontFamily),textDirection: TextDirection.rtl,
//  ),
//    ],
//  )
