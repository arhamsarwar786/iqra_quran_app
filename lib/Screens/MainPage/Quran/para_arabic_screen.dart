// ignore_for_file: file_names

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:provider/provider.dart';
import '../../../Models/aya_list_model.dart';
import '../../../Models/para_model.dart' as ParaModel;
import '../../../Models/ruko_model.dart';
import '../../../Widgets/surah_header_card.dart';
import '../../../Widgets/quran_sign_widget.dart';
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
  List<Aya> listAyat = [];

  Future<List> loadParaView() async {
    final provider = context.read<QuranDataProvider>();
    if (!provider.isLoaded) {
      await provider.loadQuranData();
    }
    String paraId = widget.parahCount.toString();
    return provider.getAyatsByPara(int.tryParse(paraId) ?? 0);
  }

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();
    var quranProvider = context.read<QuranDataProvider>();

    paraArabicScreenWidget.clear();
    List<TextSpan> textSpanChildren = [];
    String? currentSurahId;

    for (var aya in listAyat) {
      // Check for Surah change
      if (currentSurahId != aya.surahId) {
        // Flush current text block before showing Surah card
        if (textSpanChildren.isNotEmpty) {
          paraArabicScreenWidget.add(RichText(
            text: TextSpan(
              children: List.from(textSpanChildren),
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
          textSpanChildren.clear();
        }

        currentSurahId = aya.surahId;
        final metadata =
            quranProvider.getSurahMetadata(int.tryParse(aya.surahId!) ?? 0);
        if (metadata != null) {
          paraArabicScreenWidget.add(SurahHeaderCard(metadata: metadata));
        }
      }

      if (aya.ayatNumber == "0")
        continue; // Skip Bismillah since it's in the card

      // Add the ayah text (already contains inline numbers and markers)
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

      // Check for triggers requiring a block split
      bool isSajda = aya.hasSajda;
      bool isManzil = aya.manzil != null;
      bool isRuoEnd = aya.hasRuko;
      bool isArba = aya.hasArba;
      bool isNisf = aya.hasNisf;
      bool isSalsa = aya.hasSalsa;

      if (isSajda || isManzil || isRuoEnd || isArba || isNisf || isSalsa) {
        // Flush current text block
        if (textSpanChildren.isNotEmpty) {
          paraArabicScreenWidget.add(RichText(
            text: TextSpan(
              children: List.from(textSpanChildren),
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
          textSpanChildren.clear();
        }

        // Add Sajda widget if present
        if (isSajda) {
          paraArabicScreenWidget.add(const QuranSignWidget(sign: "السجدة"));
        }

        // Add Manzil widget if present
        if (isManzil) {
          paraArabicScreenWidget.add(QuranSignWidget(sign: aya.manzil!));
        }

        // Add Ruko/Division (Big Sign) widget if present
        if (isRuoEnd || isArba || isNisf || isSalsa) {
          // Find ruko metadata for numbers
          RukoModel? ruko;
          try {
            ruko = quranProvider.rukoData.firstWhere(
              (r) =>
                  r.surat.toString() == aya.surahId &&
                  r.ayaAfterRako == aya.ayatNumberInt,
            );
          } catch (e) {
            ruko = null;
          }

          String divLabel = "";
          if (isArba) divLabel = "الربع";
          if (isNisf) divLabel = "النصف";
          if (isSalsa) divLabel = "الثلاثة";

          paraArabicScreenWidget.add(QuranSignWidget(
            sign: "ع",
            label: divLabel,
            topNumber: ruko?.rakuNumber.toString(),
            middleNumber: ruko?.diff.toString(),
            bottomNumber: ruko?.bottomNumber.toString(),
          ));
        }
      }
    }

    // Flush any remaining ayahs
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

    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    loadParaView().then((val) {
      listAyat = List<Aya>.from(val);
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
                      label: "Translations"),
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
                              fontFamily: bloc.arabicFontFamily,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ];
          },

          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(
              controller: _scrollViewController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: paraArabicScreenWidget,
              ),
            ),
          ),
        ),
      );
    }));
    // )})
  }
}
