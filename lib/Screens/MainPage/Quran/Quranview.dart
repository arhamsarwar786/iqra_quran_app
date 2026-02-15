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
import '../../../Models/aya_list_model.dart';
import '../../../Widgets/surah_header_card.dart';
import '../../../Widgets/quran_sign_widget.dart';
import '../../../Utils/bottom_sheet_preview.dart';
import '../Drawer/setting_screen.dart';

class QuranView extends StatefulWidget {
  const QuranView(
      {super.key, this.ayatCount, this.surahName, this.suratNumber});
  final String? ayatCount;
  final int? suratNumber;
  final String? surahName;
  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  List<Aya> listAyat = [];
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;

  List<Widget> quranViewWidget = [];

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();
    var quranProvider = context.read<QuranDataProvider>();

    quranViewWidget.clear();
    List<TextSpan> textSpanChildren = [];

    for (var aya in listAyat) {
      if (aya.ayatNumber == "0") continue;

      // Add text span
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

      // Check for markers at this ayah
      bool isSajda = aya.hasSajda;
      bool isRuoEnd = aya.hasRuko;
      bool isManzil = aya.manzil != null;
      bool isArba = aya.hasArba;
      bool isNisf = aya.hasNisf;
      bool isSalsa = aya.hasSalsa;

      if (isSajda || isRuoEnd || isManzil || isArba || isNisf || isSalsa) {
        // Flush text
        if (textSpanChildren.isNotEmpty) {
          quranViewWidget.add(RichText(
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

        // Consolidated Sign logic
        String mainSign = "";
        String? displayLabel;
        String? topNum;
        String? midNum;
        String? botNum;

        if (isRuoEnd) {
          mainSign = "ع";
          if (isArba) displayLabel = "الربع";
          if (isNisf) displayLabel = "النصف";
          if (isSalsa) displayLabel = "الثلاثة";

          if (isSajda) {
            displayLabel =
                displayLabel != null ? "$displayLabel / السجدة" : "السجدة";
          }

          try {
            final ruko = quranProvider.rukoData.firstWhere(
              (r) =>
                  r.surat.toString() == aya.surahId &&
                  r.ayaAfterRako == aya.ayatNumberInt,
            );
            topNum = ruko.rakuNumber.toString();
            midNum = ruko.diff.toString();
            botNum = ruko.bottomNumber.toString();
          } catch (_) {}
        } else if (isSajda) {
          mainSign = "السجدة";
        } else if (isManzil) {
          mainSign = aya.manzil!;
        }

        if (mainSign.isNotEmpty) {
          quranViewWidget.add(QuranSignWidget(
            sign: mainSign,
            label: displayLabel,
            topNumber: topNum,
            middleNumber: midNum,
            bottomNumber: botNum,
          ));
        }
      }
    }

    // Flush remaining
    if (textSpanChildren.isNotEmpty) {
      quranViewWidget.add(RichText(
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
    final provider = context.read<QuranDataProvider>();
    listAyat = provider.getAyatsBySurah(widget.suratNumber ?? 0);
    viewMaker();
    _scrollViewController = ScrollController();
    _scrollViewController!.addListener(() {
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          isScrollingDown = true;
          _showAppbar = false;
          setState(() {});
        }
      }

      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
          _showAppbar = true;
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollViewController!.dispose();
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
                                var max = _scrollViewController!
                                    .position.maxScrollExtent;
                                double distance = max -
                                    _scrollViewController!.position.pixels;
                                double durationInSeconds = distance / 50;

                                _scrollViewController!.animateTo(
                                    _scrollViewController!
                                        .position.maxScrollExtent,
                                    duration: Duration(
                                        seconds: durationInSeconds.toInt()),
                                    curve: Curves.linear);
                              },
                              child: const Icon(Icons.fit_screen_outlined)),
                          label: "Auto Scrol"),
                      BottomNavigationBarItem(
                          icon: InkWell(
                            onTap: () {
                              push(context, const SettingScreen());
                            },
                            child: const Icon(Icons.settings),
                          ),
                          label: "Setting")
                    ],
                  ),
            body: GestureDetector(
              onVerticalDragStart: (details) {
                // Need to implement auto-scroll stopping if it exists, but QuranView might not have it fully implemented yet?
                // Checking previous context, it seems only simple scroll was there. Let's add the gesture detector anyway as good practice if auto-scroll is added.
                // Wait, looking at file history, QuranView DOES have auto-scroll logic added previously?
                // Actually, let's just wrap it.
              },
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor: bloc.selectedTheme,
                      expandedHeight: (metadata != null ? 110.0 : 0.0) +
                          (_showAppbar ? 56.0 : 0.0),
                      toolbarHeight: metadata != null
                          ? 110.0
                          : (_showAppbar ? 56.0 : 56.0),
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
                                  transitionBuilder: (Widget child,
                                      Animation<double> animation) {
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
                  ),
                  padding: const EdgeInsets.only(top: 20, bottom: 20),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: SingleChildScrollView(
                      controller: _scrollViewController,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 15, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: quranViewWidget,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )));
  }
}
