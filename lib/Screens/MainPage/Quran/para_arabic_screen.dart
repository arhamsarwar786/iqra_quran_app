// ignore_for_file: file_names

import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:provider/provider.dart';
import '../../../Models/aya_list_model.dart';
import '../../../Models/para_model.dart' as ParaModel;
import '../../../Models/ruko_model.dart';
import '../../../Models/sajda_model.dart';
import '../../../Utils/bottom_sheet_preview.dart';

class ParaArabicScreen extends StatefulWidget {
  const ParaArabicScreen(
      {super.key, this.para, this.ayatInPara, this.parahCount, this.parahname});
  final String? parahCount;
  final int? ayatInPara;
  final ParaModel.Para? para;
  final String? parahname;
  @override
  State<ParaArabicScreen> createState() => _ParaArabicScreenState();
}

class _ParaArabicScreenState extends State<ParaArabicScreen> {
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;

  List<Widget> paraArabicScreenWidget = [];
  List listAyat = [];

  Future<List<RukoModel>> getRuko() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/ruko.json");
    var rukoDataLocal = rukoModelFromJson(data);
    List<RukoModel> rukoData = rukoDataLocal
        .where((element) => 
            listAyat.any((aya) => (aya as Aya).surahId == element.surat.toString()))
        .toList();
    return rukoData;
  }

  Future<List<SajdaModel>> getSajda() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/sajda.json");
    var sajdaDataLocal = sajdaModelFromJson(data);
    List<SajdaModel> sajdaData = sajdaDataLocal
        .where((element) => 
            listAyat.any((aya) => (aya as Aya).surahId == element.surat.toString()))
        .toList();
    return sajdaData;
  }

  Future<List> loadParaView() async {
    final quran = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/quran2026.json");
    final quranResponse = jsonDecode(quran) as List;
    String paraId = widget.parahCount.toString();
    final paraAyat = [];
    
    for (var item in quranResponse) {
      if (item["paraId"].toString() == paraId) {
        paraAyat.add(Aya.fromJson(item));
      }
    }

    return paraAyat;
  }

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();
    List<RukoModel> rukoList = await getRuko();
    
    // Group ayats by surah to handle ruku properly
    Map<String, List<Aya>> ayatsBySurah = {};
    for (var aya in listAyat) {
      var ayaObj = aya as Aya;
      String surahId = ayaObj.surahId ?? "0";
      if (!ayatsBySurah.containsKey(surahId)) {
        ayatsBySurah[surahId] = [];
      }
      ayatsBySurah[surahId]!.add(ayaObj);
    }

    // Process each surah's rukus
    for (var surahId in ayatsBySurah.keys) {
      var surahAyats = ayatsBySurah[surahId]!;
      var surahRukus = rukoList.where((r) => r.surat.toString() == surahId).toList();
      
      if (surahRukus.isEmpty) {
        // No rukus for this surah, just add all ayats
        List<TextSpan> textSpanChildren = [];
        for (var aya in surahAyats) {
          if (aya.ayatNumber == "0") continue;
          
          textSpanChildren.add(
            TextSpan(
              text: "${(aya.arabicText).trim()} ",
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  SHEET.bottomSheetPreview(context, aya, bloc);
                },
            ),
          );
          
          if (aya.sajda != null) {
            paraArabicScreenWidget.add(RichText(
              text: TextSpan(
                children: textSpanChildren,
                style: TextStyle(
                    fontSize: bloc.arabicFontSize,
                    fontFamily: bloc.arabicFontFamily,
                    color: Colors.black),
              ),
            ));
            textSpanChildren = [];
            
            paraArabicScreenWidget.add(Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  aya.sajda!,
                  style: MyTextStyle.heading1.copyWith(
                      fontSize: 30,
                      fontFamily: bloc.arabicFontFamily,
                      color: bloc.selectedTheme),
                ),
              ],
            ));
          }
          
          if (aya.manzil != null) {
            paraArabicScreenWidget.add(RichText(
              text: TextSpan(
                children: textSpanChildren,
                style: TextStyle(
                    fontSize: bloc.arabicFontSize,
                    fontFamily: bloc.arabicFontFamily,
                    color: Colors.black),
              ),
            ));
            textSpanChildren = [];
            
            paraArabicScreenWidget.add(const SizedBox(height: 10));
            paraArabicScreenWidget.add(Stack(
              alignment: Alignment.topLeft,
              children: [
                Text(
                  aya.manzil!,
                  style: MyTextStyle.heading1.copyWith(
                      fontSize: 24,
                      fontFamily: bloc.arabicFontFamily,
                      color: bloc.selectedTheme),
                ),
              ],
            ));
            paraArabicScreenWidget.add(const SizedBox(height: 10));
          }
        }
        
        if (textSpanChildren.isNotEmpty) {
          paraArabicScreenWidget.add(RichText(
            text: TextSpan(
              children: textSpanChildren,
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
        }
        continue;
      }

      // Process rukus for this surah
      for (var i = 0; i < surahRukus.length; i++) {
        int start = i > 0 ? surahRukus[i - 1].ayaBeforeRako : 0;
        int next = surahRukus[i].ayaAfterRako + 1;
        
        var ayaList = surahAyats.where((a) {
          int ayaNum = int.tryParse(a.ayatNumber ?? "0") ?? 0;
          return ayaNum >= start && ayaNum < next;
        }).toList();
        
        List<TextSpan> textSpanChildren = [];
        
        for (var aya in ayaList) {
          if (aya.ayatNumber == "0") continue;
          
          textSpanChildren.add(
            TextSpan(
              text: "${(aya.arabicText).trim()} ",
              style: const TextStyle(color: Colors.black),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  SHEET.bottomSheetPreview(context, aya, bloc);
                },
            ),
          );
          
          if (aya.sajda != null) {
            paraArabicScreenWidget.add(RichText(
              text: TextSpan(
                children: textSpanChildren,
                style: TextStyle(
                    fontSize: bloc.arabicFontSize,
                    fontFamily: bloc.arabicFontFamily,
                    color: Colors.black),
              ),
            ));
            textSpanChildren = [];
            
            paraArabicScreenWidget.add(Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  aya.sajda!,
                  style: MyTextStyle.heading1.copyWith(
                      fontSize: 30,
                      fontFamily: bloc.arabicFontFamily,
                      color: bloc.selectedTheme),
                ),
              ],
            ));
          }
          
          if (aya.manzil != null) {
            paraArabicScreenWidget.add(const SizedBox(height: 10));
            paraArabicScreenWidget.add(Stack(
              alignment: Alignment.topLeft,
              children: [
                Text(
                  aya.manzil!,
                  style: MyTextStyle.heading1.copyWith(
                      fontSize: 24,
                      fontFamily: bloc.arabicFontFamily,
                      color: bloc.selectedTheme),
                ),
              ],
            ));
            paraArabicScreenWidget.add(const SizedBox(height: 10));
          }
        }
        
        paraArabicScreenWidget.add(RichText(
          text: TextSpan(
            children: textSpanChildren,
            style: TextStyle(
                fontSize: bloc.arabicFontSize,
                fontFamily: bloc.arabicFontFamily,
                color: Colors.black),
          ),
        ));
        
        paraArabicScreenWidget.add(Stack(
          alignment: Alignment.center,
          children: [
            Text(
              "ع",
              style: MyTextStyle.heading1.copyWith(
                  fontSize: 70,
                  fontFamily: bloc.arabicFontFamily,
                  color: bloc.selectedTheme),
            ),
            Positioned(bottom: 30, child: Text(surahRukus[i].diff.toString())),
            Positioned(top: 20, child: Text(surahRukus[i].rakuNumber.toString())),
            Positioned(bottom: 0, child: Text(surahRukus[i].bottomNumber.toString()))
          ],
        ));
      }
    }
    
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadParaView().then((val) {
      listAyat = val;
      viewMaker();
    });
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

  @override
  void dispose() {
    _scrollViewController!.dispose();
    _scrollViewController!.removeListener(() {});
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          child: Text(listAyat.length.toString()),
        ),
        bottomNavigationBar: isScrollingDown
            ? const SizedBox()
            : BottomNavigationBar(
                backgroundColor: bloc.selectedTheme,
                items: [
                  BottomNavigationBarItem(
                      icon: InkWell(
                          onTap: () {
                            // push(
                            //     context,
                            //     SurahTranslationScreen(
                            //       ayatCount: widget.ayatCount.toString(),
                            //       ayatList: widget.ayat,
                            //       suratNumber: widget.suratNumber,
                            //       surahName: widget.surahName,
                            //     ));
                          },
                          child: const Icon(Icons.book)),
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
                          child: const Icon(Icons.fit_screen_outlined)),
                      label: "Auto Scrol"),
                  const BottomNavigationBarItem(
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
                    margin: const EdgeInsets.only(top: 0),
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
                                color: const Color.fromARGB(255, 255, 109, 109),
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
                        const SizedBox(
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
                                color: const Color.fromARGB(255, 255, 109, 109),
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
                        duration: const Duration(milliseconds: 200),
                        child: AppBar(
                          centerTitle: true,
                          iconTheme: const IconThemeData(
                            color: Colors.black,
                          ),
                          backgroundColor: Colors.white,
                          title: Text(
                            widget.parahname ?? 'Para ${widget.parahCount}',
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
                  padding: const EdgeInsets.all(2),
                  // height: size.height / 1.75,

                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      controller: _scrollViewController,
                      child: Column(
                        children: paraArabicScreenWidget,
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
