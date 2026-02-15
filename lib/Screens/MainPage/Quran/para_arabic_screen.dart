// ignore_for_file: file_names

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Models/aya_list_model.dart';
import '../../../Models/para_model.dart' as ParaModel;
import '../../../Models/surah_metadata_model.dart';
import '../../../Widgets/surah_header_card.dart';
import '../../../Widgets/quran_sign_widget.dart';
import '../../../Utils/bottom_sheet_preview.dart';
import '../../../Widgets/auto_scroll_speed_dialog.dart';
import '../Drawer/setting_screen.dart';

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
  bool isAutoScrolling = false;
  double autoScrollSpeed = 1.0;

  List<Widget> paraArabicScreenWidget = [];
  List<Aya> listAyat = [];
  SurahMetadata? firstSurahMetadata;
  SurahMetadata? currentSurahMetadata;
  Map<String, GlobalKey> surahHeaderKeys = {};

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
    surahHeaderKeys.clear();
    firstSurahMetadata = null;
    currentSurahMetadata = null;

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
          if (firstSurahMetadata == null) {
            firstSurahMetadata = metadata;
            currentSurahMetadata = metadata;
          } else {
            final key = GlobalKey();
            surahHeaderKeys[aya.surahId!] = key;
            paraArabicScreenWidget.add(Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: SurahHeaderCard(
                key: key,
                metadata: metadata,
              ),
            ));
          }
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

        // Determine consolidated content for the sign widget
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

          // Find ruko metadata
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
          paraArabicScreenWidget.add(QuranSignWidget(
            sign: mainSign,
            label: displayLabel,
            topNumber: topNum,
            middleNumber: midNum,
            bottomNumber: botNum,
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

  void _updateCurrentSurah() {
    if (firstSurahMetadata == null) return;

    SurahMetadata? bestMatch = firstSurahMetadata;
    double threshold = 200.0; // The distance from top to switch header

    // Since map iteration order might be insertion order, we can rely on it
    // as we added Surah headers in order in viewMaker.
    surahHeaderKeys.forEach((surahId, key) {
      final context = key.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;

        // If the inline header has scrolled up past the threshold, it becomes the active surah
        if (position <= threshold) {
          final qProvider = context.read<QuranDataProvider>();
          final metadata =
              qProvider.getSurahMetadata(int.tryParse(surahId) ?? 0);
          if (metadata != null) {
            bestMatch = metadata;
          }
        }
      }
    });

    if (currentSurahMetadata?.index != bestMatch?.index) {
      setState(() {
        currentSurahMetadata = bestMatch;
      });
    }
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
      // Standard appbar hide/show logic
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

      // Sticky header logic
      _updateCurrentSurah();
    });
  }

  void _startAutoScroll() {
    if (!isAutoScrolling) return;

    // Calculate duration based on remaining distance and speed
    // Base speed: 50 pixels per second at 1.0x
    // Higher speed factor -> Faster scroll (Less duration per pixel)

    double currentPixels = _scrollViewController!.position.pixels;
    double maxPixels = _scrollViewController!.position.maxScrollExtent;
    double remainingDistance = maxPixels - currentPixels;

    if (remainingDistance <= 0) {
      setState(() {
        isAutoScrolling = false;
        _showAppbar = true;
        isScrollingDown = false;
      });
      return;
    }

    // Adjust these constants to tune the "feel" of 1x speed
    double pixelsPerSecond = 30.0 * autoScrollSpeed;
    double durationSeconds = remainingDistance / pixelsPerSecond;

    _scrollViewController!
        .animateTo(
      maxPixels,
      duration: Duration(milliseconds: (durationSeconds * 1000).toInt()),
      curve: Curves.linear,
    )
        .then((_) {
      // creating a loop check if needed or just completion
      if (isAutoScrolling &&
          _scrollViewController!.position.pixels >=
              _scrollViewController!.position.maxScrollExtent) {
        setState(() {
          isAutoScrolling = false;
          _showAppbar = true;
          isScrollingDown = false;
        });
      }
    });

    setState(() {
      _showAppbar = false;
      isScrollingDown = true; // Hides bottom bar
    });
  }

  void _stopAutoScroll() {
    _scrollViewController!.jumpTo(_scrollViewController!.position.pixels);
    setState(() {
      isAutoScrolling = false;
      _showAppbar = true;
      isScrollingDown = false;
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
        bottomNavigationBar: isScrollingDown
            ? const SizedBox()
            : BottomNavigationBar(
                backgroundColor: bloc.selectedTheme,
                selectedItemColor: Colors.white,
                unselectedItemColor: Colors.white,
                items: [
                  BottomNavigationBarItem(
                      icon: InkWell(
                          onTap: () {},
                          child: const Icon(Icons.book, color: Colors.white)),
                      label: "Translations"),
                  BottomNavigationBarItem(
                      icon: InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => AutoScrollSpeedDialog(
                                currentSpeedFactor: autoScrollSpeed,
                                isScrolling: isAutoScrolling,
                                onSpeedChanged: (val) {
                                  autoScrollSpeed = val;
                                },
                                onStart: () {
                                  setState(() {
                                    isAutoScrolling = true;
                                  });
                                  _startAutoScroll();
                                },
                                onStop: () {
                                  _stopAutoScroll();
                                },
                              ),
                            );
                          },
                          child: Icon(
                            isAutoScrolling
                                ? Icons.stop_circle_outlined
                                : Icons.fit_screen_outlined,
                            color: Colors.white,
                          )),
                      label: isAutoScrolling ? "Stop" : "Auto Scroll"),
                  BottomNavigationBarItem(
                      icon: InkWell(
                        onTap: () {
                          push(context, const SettingScreen());
                        },
                        child: const Icon(Icons.settings, color: Colors.white),
                      ),
                      label: "Setting")
                ],
              ),
        body: GestureDetector(
          onVerticalDragStart: (details) {
            if (isAutoScrolling) {
              _stopAutoScroll();
            }
          },
          child: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  backgroundColor: bloc.selectedTheme,
                  expandedHeight: (currentSurahMetadata != null ? 110.0 : 0.0) +
                      (_showAppbar ? 56.0 : 0.0),
                  toolbarHeight: currentSurahMetadata != null
                      ? 110.0
                      : (_showAppbar ? 56.0 : 56.0),
                  floating: false,
                  pinned: true,
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
                                widget.parahname ?? 'Para ${widget.parahCount}',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontFamily: bloc.arabicFontFamily,
                                ),
                              ),
                            ),
                          ),
                          if (currentSurahMetadata != null)
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              transitionBuilder:
                                  (Widget child, Animation<double> animation) {
                                return FadeTransition(
                                    opacity: animation, child: child);
                              },
                              child: SurahHeaderCard(
                                key: ValueKey(currentSurahMetadata!.index),
                                metadata: currentSurahMetadata!,
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
              padding: const EdgeInsets.only(top: 5, bottom: 20),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: SingleChildScrollView(
                  controller: _scrollViewController,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 15, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: paraArabicScreenWidget,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }));
  }
}
