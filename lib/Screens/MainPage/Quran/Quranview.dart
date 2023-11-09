// ignore_for_file: file_names

import 'dart:convert';
import 'dart:developer';

import 'package:collection/collection.dart'; // You have to add this manually, for some reason it cannot be added automatically

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
import '../../../Utils/constants.dart';
import '../../../widgets.dart';

class QuranView extends StatefulWidget {
  QuranView({ this.ayatCount, this.surahName, this.ayat, this.suratNumber});
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





  getRuko() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/ruko.json");
    var rukoDataLocal = rukoModelFromJson(data);
    rukoData = rukoDataLocal.where((element) => element.surat == widget.suratNumber.toString() ).toList();
    setState(() {});
  }

    getSajda() async {
    var data = await DefaultAssetBundle.of(context)
        .loadString("assets/extraction/sajda.json");
    var sajdaDataLocal = sajdaModelFromJson(data);
    sajdaData = sajdaDataLocal.where((element) => element.surat == widget.suratNumber.toString() ).toList();
    // debugger();
    // print(sajdaData);
    setState(() {});
  }

  List<RukoModel>? rukoData;
  List<SajdaModel>? sajdaData;

  @override
  void initState() {
    super.initState();
    getArabic();
    getRuko();
    getSajda();
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


  isRuku(index){
    var data = rukoData?.firstWhereOrNull((element) => (element.ayaAfterRako == index.toString()));
  return  data;
  }

    isSajda(index){
    var data = sajdaData?.firstWhereOrNull((element) => (element.ayaBeforeSajda == index.toString()));
  return  data;
  }

  String arabicText = "";


  getArabic(){
    for(int index = 0; index < int.parse(widget.ayatCount.toString()); index++){
    arabicText += "${widget.ayat![index].arabic}${index == 0 ? '\n' : " "}";
    }
    setState(() {
      
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(child: Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
          bottomNavigationBar:isScrollingDown?SizedBox(): BottomNavigationBar(
            backgroundColor: bloc.selectedTheme,
            items: [
              BottomNavigationBarItem(icon: InkWell(
                onTap: (){
                  push(context, SurahTranslationScreen(                     
                                                ayatCount:widget.ayatCount.toString(),
                                                ayatList: widget.ayat,
                                                suratNumber: widget.suratNumber,
                                                surahName: widget.surahName,
                  ));
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
                                    "assets/images/borderLeft1.png",color: Color.fromARGB(255, 255, 109, 109),),
                              ),
                              Expanded(
                                child: Image.asset(
                                    "assets/images/borderRight1.png",color: Colors.white,),
                              ),
                            ],
                          ),
                          SizedBox(height: 5,),
                          Text(
                            "بِسْمِ اللَّهِ الرَّحْمَـٰنِ الرَّحِيمِ",
                            style: MyTextStyle.heading2.copyWith(
                                color: Colors.white,
                                fontSize: 10,
                                fontFamily: bloc.arabicFontFamily),
                          ),
                          SizedBox(height: 5,),

                             Row(
                            children: [
                              Expanded(
                                child: Image.asset(
                                    "assets/images/borderLeft1.png",color: Colors.white,),
                              ),
                              Expanded(
                                child: Image.asset(
                                    "assets/images/borderRight1.png",color: Color.fromARGB(255, 255, 109, 109),),
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
            body: Container(
                      padding: EdgeInsets.all(10),
                      // height: size.height / 1.75,
                      child: SingleChildScrollView(
                              controller: _scrollViewController,
                              child: Column(
                                children: [
//              ListView.builder(
//                  // controller: _scrollViewController,
//                  physics:
//                      const NeverScrollableScrollPhysics(),
//                  shrinkWrap: true,
//                  itemCount: widget.ayat!.length,
//                  itemBuilder: (context, index) {
//                   RukoModel? rukoModel =  isRuku(index);
//                   SajdaModel? sajdaModel =  isSajda(index);
//                    return Column(
//                      children: [
//                       Divider(),
//                        Divider(),
//                        Divider(),
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
//                        Divider(),
//                        Divider(),
//                        Divider(),
//                        Text("ترجمہ: کنزالایمان"),
//                         Text(
//                          widget.ayat![index].translation1.toString(),
//                          // " (" +
//                          // arabicNumber.convert(index) +
//                          // ")",
//                          textAlign: TextAlign.right,
//                          style: TextStyle(
//                            fontSize: bloc.urduFontSize,fontFamily: bloc.urduFontFamily,
//                           fontWeight: FontWeight.w500
//                              ),
//                        ),
//                        Divider(),
//                        Divider(),
//                        Divider(),
//                         Text(
//                          widget.ayat![index].translation2.toString(),
//                          // " (" +
//                          // arabicNumber.convert(index) +
//                          // ")",
//                          textAlign: TextAlign.right,
//                          style: TextStyle(
//                            fontSize: bloc.urduFontSize,fontFamily: bloc.urduFontFamily,
//                           fontWeight: FontWeight.w500
//                              ),
//                        ),
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
//                            Stack(
//                             alignment: Alignment.center,
//                              children: [
//                                Text(
//                                  "ع",
//                                  style: MyTextStyle.heading1
//                                      .copyWith(
//                                          fontSize: 70,
//                                          fontFamily: bloc
//                                              .arabicFontFamily),
//                                ),
//                                Positioned(
//                                 bottom: 30,
//                                 child: Text(rukoModel.diff)),
//                                 Positioned(
//                                 top: 20,
//                                 child: Text(rukoModel.rakuNumber))
//                              ],
//                            ),
                          
                          
//                           //  Expanded(
//                               //  child: Image.asset(
//                               //      "assets/images/borderRight${bloc.iconNumber}.png")),
//                          ],
//                        )
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
                   Text(                     
                     arabicText,
                     textAlign: TextAlign.right,
                     style: MyTextStyle.heading3.copyWith(fontSize: bloc.arabicFontSize,fontFamily: bloc.arabicFontFamily),textDirection: TextDirection.rtl,
                   ),
              //    ],
              //  )
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
