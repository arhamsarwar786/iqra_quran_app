// ignore_for_file: file_names

import 'package:flutter/gestures.dart';

import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/translation/surah_translation_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:provider/provider.dart';
// import 'arabic';
import '../../../Models/aya_list_model.dart';
import '../../../Models/ruko_model.dart';
import '../../../Models/sajda_model.dart';
import '../../../Widgets/surah_header_card.dart';
import '../../../Widgets/quran_sign_widget.dart';
import '../../../Utils/bottom_sheet_preview.dart';

class QuranView extends StatefulWidget {
  const QuranView(
      {super.key, this.ayatCount, this.surahName, this.suratNumber});
  final String? ayatCount;
  final int? suratNumber;
  // List<Aya>? ayat;
  final String? surahName;
  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  List<Aya> listAyat = [];
  List<RukoModel> rukoData = [];
  List<SajdaModel> sajdaData = [];
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;

  Future<List<RukoModel>> getRuko() async {
    final provider = context.read<QuranDataProvider>();
    rukoData = provider.rukoData
        .where((element) => element.surat == (widget.suratNumber ?? 0))
        .toList();
    return rukoData;
  }

  Future<List<SajdaModel>> getSajda() async {
    final provider = context.read<QuranDataProvider>();
    sajdaData = provider.sajdaData
        .where((element) =>
            element.surat.toString() == widget.suratNumber.toString())
        .toList();

    return sajdaData;
  }

  List<Widget> quranViewWidget = [];

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();

    quranViewWidget.clear();

    List<RukoModel> rukoList = await getRuko();
    for (var i = 0; i < rukoList.length; i++) {
      // debugger();
      int start = i > 0 ? rukoList[i - 1].ayaAfterRako : 0;
      int next = rukoList[i].ayaAfterRako;

      if (start >= listAyat.length) break;
      int end = next > listAyat.length ? listAyat.length : next;

      var ayaList = listAyat.sublist(start, end);
      List<TextSpan> textSpanChildren = [];

      for (int k = 0; k < ayaList.length; k++) {
        var aya = ayaList[k] as Aya;
        if (aya.sajda != null) {
          var newList = ayaList.sublist(k + 1, ayaList.length);
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
          quranViewWidget.add(RichText(
            text: TextSpan(
              children: textSpanChildren,
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
          textSpanChildren = [];

          quranViewWidget.add(QuranSignWidget(sign: aya.sajda!));

          for (var a in newList) {
            var ayaObj = a as Aya;
            textSpanChildren.add(
              TextSpan(
                text: "${(ayaObj.arabicText).trim()} ",
                style: const TextStyle(color: Colors.black),
                recognizer: TapGestureRecognizer()
                  ..onTap = () {
                    SHEET.bottomSheetPreview(context, ayaObj, bloc);
                  },
              ),
            );
          }
          break;
        } else {
          if (aya.ayatNumber == "0") {
            continue;
          }

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
          if (aya.manzil != null) {
            quranViewWidget.add(QuranSignWidget(sign: aya.manzil!));
          }
        }
      }
      quranViewWidget.add(RichText(
        text: TextSpan(
          children: textSpanChildren,
          style: TextStyle(
              fontSize: bloc.arabicFontSize,
              fontFamily: bloc.arabicFontFamily,
              color: Colors.black),
        ),
      ));

      quranViewWidget.add(QuranSignWidget(
        sign: "ع",
        topNumber: rukoList[i].rakuNumber.toString(),
        middleNumber: rukoList[i].diff.toString(),
        bottomNumber: rukoList[i].bottomNumber.toString(),
      ));
    }
    setState(() {});
  }

  bool isBismilla = false;
  String bismillaArabic = "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ";

  @override
  void initState() {
    super.initState();
    final provider = context.read<QuranDataProvider>();
    listAyat = provider.getAyatsBySurah(widget.suratNumber ?? 0);
    viewMaker();
    _scrollViewController = ScrollController();
    _scrollViewController!.addListener(() {
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          _showAppbar = false; // Hide on scroll down
          setState(() {});
        }
      }

      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          _showAppbar = true; // Show on scroll up
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
    final bloc = context.watch<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final metadata = quranProvider.getSurahMetadata(widget.suratNumber ?? 0);

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        bottomNavigationBar: isScrollingDown
            ? const SizedBox()
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
                                  ayatList: listAyat,
                                  suratNumber: widget.suratNumber,
                                  surahName: widget.surahName,
                                ));
                          },
                          child: const Icon(Icons.book)),
                      label: "Translation"),
                  BottomNavigationBarItem(
                      icon: InkWell(
                          onTap: () {
                            var max =
                                _scrollViewController!.position.maxScrollExtent;
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
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverAppBar(
                automaticallyImplyLeading: false,
                backgroundColor: bloc.selectedTheme,
                expandedHeight: metadata != null ? 166.0 : 56.0,
                toolbarHeight: metadata != null ? 110.0 : 56.0,
                floating: false,
                pinned: true,
                snap: false,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        AnimatedContainer(
                          height: _showAppbar ? 56.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: AppBar(
                            centerTitle: true,
                            elevation: 0,
                            iconTheme: const IconThemeData(
                              color: Colors.black,
                            ),
                            backgroundColor: Colors.white,
                            title: Text(
                              '${widget.surahName}',
                              style: TextStyle(
                                color: Colors.black,
                                fontFamily: bloc.arabicFontFamily,
                              ),
                            ),
                          ),
                        ),
                        if (metadata != null)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            child: SurahHeaderCard(
                              key: ValueKey(metadata.index),
                              metadata: metadata,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ];
          },
          body: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage("assets/images/border.png"),
                fit: BoxFit.fill,
                alignment: Alignment.topCenter,
              ),
            ),
            padding: const EdgeInsets.only(top: 20, bottom: 20),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                controller: _scrollViewController,
                child: Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: quranViewWidget,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
