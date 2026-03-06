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
import '../../../Helper/preference/saved_preferences.dart';
import '../../../Utils/bottom_sheet_preview.dart';
import '../../../Widgets/auto_scroll_speed_dialog.dart';
import '../Drawer/setting_screen.dart';

class QuranView extends StatefulWidget {
  final String? ayatCount;
  final int? suratNumber;
  final String? surahName;
  final int? targetAyatNumber;
  final double? initialScrollOffset;
  final bool saveLastRead;

  const QuranView({
    super.key,
    this.ayatCount,
    this.suratNumber,
    this.surahName,
    this.targetAyatNumber,
    this.initialScrollOffset,
    this.saveLastRead = true,
  });

  @override
  State<QuranView> createState() => _QuranViewState();
}

class _QuranViewState extends State<QuranView> {
  List<Aya> listAyat = [];
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool _showAppbar = true;
  bool isScrollingDown = true;
  GlobalKey? _targetKey;
  bool _hasInitialScrolled = false;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false;
  double autoScrollSpeed = 1.0;

  List<Widget> quranViewWidget = [];

  viewMaker() async {
    var bloc = context.read<ThemeProvider>();
    var quranProvider = context.read<QuranDataProvider>();

    quranViewWidget.clear();
    List<InlineSpan> textSpanChildren = [];
    List<int> currentBatchAyatNumbers = []; // Track ayats in current batch

    for (var aya in listAyat) {
      if (aya.ayatNumber == "0") continue;

      currentBatchAyatNumbers.add(aya.ayatNumberInt);

      bool isTargetAyat =
          _highlightedAyah != null && aya.ayatNumberInt == _highlightedAyah;

      // Clean text by removing trailing bracketed numbers
      String text = aya.arabicText.trim();
      text = text.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '');

      textSpanChildren.add(
        TextSpan(
          text: "$text ",
          style: TextStyle(
            color: isTargetAyat ? bloc.selectedTheme : Colors.black,
            fontWeight: isTargetAyat ? FontWeight.w700 : FontWeight.normal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              SHEET.bottomSheetPreview(
                  context, listAyat, listAyat.indexOf(aya), bloc);
            },
        ),
      );

      // Add decorative verse marker
      textSpanChildren.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTargetAyat
                    ? bloc.selectedTheme.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: Text(
              arabicNumber.convert(aya.ayatNumberInt),
              style: TextStyle(
                fontSize: (bloc.arabicFontSize * 0.45).clamp(10, 16),
                fontWeight: FontWeight.bold,
                fontFamily: bloc.arabicFontFamily,
                color: isTargetAyat ? bloc.selectedTheme : Colors.black54,
              ),
            ),
          ),
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
          GlobalKey? keyForThisBlock;
          // Check if target ayat is in this block
          if (_highlightedAyah != null &&
              currentBatchAyatNumbers.contains(_highlightedAyah)) {
            keyForThisBlock = GlobalKey();
            _targetKey = keyForThisBlock;
          }

          quranViewWidget.add(Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: RichText(
              key: keyForThisBlock,
              textAlign: TextAlign.center,
              text: TextSpan(
                children: List<InlineSpan>.from(textSpanChildren),
                style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black,
                  height: 1.8,
                ),
              ),
            ),
          ));
          textSpanChildren.clear();
          currentBatchAyatNumbers.clear(); // Reset batch tracking
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
      GlobalKey? keyForThisBlock;
      // Check if target ayat is in this last block
      if (_highlightedAyah != null &&
          currentBatchAyatNumbers.contains(_highlightedAyah)) {
        keyForThisBlock = GlobalKey();
        _targetKey = keyForThisBlock;
      }

      quranViewWidget.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: RichText(
          key: keyForThisBlock,
          textAlign: TextAlign.center,
          text: TextSpan(
            children: List<InlineSpan>.from(textSpanChildren),
            style: TextStyle(
              fontSize: bloc.arabicFontSize,
              fontFamily: bloc.arabicFontFamily,
              color: Colors.black,
              height: 1.8,
            ),
          ),
        ),
      ));
    }

    setState(() {});

    if (widget.initialScrollOffset != null && !_hasInitialScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollViewController!.hasClients) {
          // Delay briefly to allow proper layout
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollViewController!.hasClients) {
              _scrollViewController!.jumpTo(widget.initialScrollOffset!);
            }
          });
        }
        _hasInitialScrolled = true;
      });
    } else if (_targetKey != null) {
      // Trigger scroll if target key is set
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_targetKey!.currentContext != null) {
          Scrollable.ensureVisible(
            _targetKey!.currentContext!,
            duration: Duration.zero, // Instant jump like last read
            alignment: 0.1, // Align slightly from top
          );
        }
      });
    }
  }

  int? _highlightedAyah;

  @override
  void initState() {
    super.initState();
    _highlightedAyah = widget.targetAyatNumber;
    final provider = context.read<QuranDataProvider>();
    listAyat = provider.getAyatsBySurah(widget.suratNumber ?? 0);

    // Save as last read
    if (widget.saveLastRead) {
      SavedPrefernces.setLastRead({
        "type": "surah",
        "id": widget.suratNumber,
        "name": widget.surahName,
        "count": widget.ayatCount,
      });
    }

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

  void _startAutoScroll() {
    if (!isAutoScrolling) return;
    final ctrl = _scrollViewController!;
    final remaining = ctrl.position.maxScrollExtent - ctrl.position.pixels;
    if (remaining <= 0) {
      setState(() {
        isAutoScrolling = false;
        _showAppbar = true;
        isScrollingDown = false;
      });
      return;
    }
    final duration = remaining / (30.0 * autoScrollSpeed);
    ctrl
        .animateTo(
      ctrl.position.maxScrollExtent,
      duration: Duration(milliseconds: (duration * 1000).toInt()),
      curve: Curves.linear,
    )
        .then((_) {
      if (isAutoScrolling &&
          ctrl.position.pixels >= ctrl.position.maxScrollExtent) {
        setState(() {
          isAutoScrolling = false;
          _showAppbar = true;
          isScrollingDown = false;
        });
      }
    });
    setState(() {
      _showAppbar = false;
      isScrollingDown = true;
    });
  }

  void _pauseAutoScrollForTouch() {
    if (!isAutoScrolling) return;
    _scrollViewController!.jumpTo(_scrollViewController!.position.pixels);
    _isScrollPaused = true;
  }

  void _resumeAutoScrollAfterTouch() {
    if (!isAutoScrolling || !_isScrollPaused) return;
    _isScrollPaused = false;
    _startAutoScroll();
  }

  /// Only called by the Stop button — fully cancels auto-scroll.
  void _stopAutoScroll() {
    _scrollViewController!.jumpTo(_scrollViewController!.position.pixels);
    setState(() {
      isAutoScrolling = false;
      _isScrollPaused = false;
      _showAppbar = true;
      isScrollingDown = false;
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
                : Theme(
                    data: Theme.of(context).copyWith(
                      canvasColor: bloc.selectedTheme,
                    ),
                    child: BottomNavigationBar(
                      backgroundColor: bloc.selectedTheme,
                      elevation: 10,
                      selectedItemColor: Colors.white,
                      unselectedItemColor: Colors.white,
                      selectedFontSize: 12,
                      unselectedFontSize: 12,
                      selectedLabelStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      unselectedLabelStyle:
                          const TextStyle(color: Colors.white),
                      currentIndex: 0,
                      type: BottomNavigationBarType.fixed,
                      onTap: (index) {
                        if (index == 0) {
                          push(
                              context,
                              SurahTranslationScreen(
                                ayatCount: widget.ayatCount.toString(),
                                ayatList: listAyat,
                                suratNumber: widget.suratNumber,
                                surahName: widget.surahName,
                              ));
                        } else if (index == 1) {
                          showDialog(
                            context: context,
                            builder: (context) => AutoScrollSpeedDialog(
                              currentSpeedFactor: autoScrollSpeed,
                              isScrolling: isAutoScrolling,
                              onSpeedChanged: (val) {
                                setState(() {
                                  autoScrollSpeed = val;
                                });
                                if (isAutoScrolling) {
                                  _stopAutoScroll();
                                  _startAutoScroll();
                                }
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
                        } else if (index == 2) {
                          push(context, const SettingScreen());
                        }
                      },
                      items: [
                        BottomNavigationBarItem(
                          icon: const Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          label: bloc.selectedTranslation == "irfan"
                              ? "Kanz-ul-Irfan"
                              : "Kanz-ul-Iman",
                        ),
                        BottomNavigationBarItem(
                          icon: Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(
                              isAutoScrolling
                                  ? Icons.stop_circle_rounded
                                  : Icons.fit_screen_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          label: isAutoScrolling ? 'Stop' : 'Auto Scroll',
                        ),
                        const BottomNavigationBarItem(
                          icon: Padding(
                            padding: EdgeInsets.only(bottom: 4.0),
                            child: Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          label: "Setting",
                        )
                      ],
                    ),
                  ),
            body: Listener(
              onPointerDown: (_) => _pauseAutoScrollForTouch(),
              onPointerUp: (_) => _resumeAutoScrollAfterTouch(),
              onPointerCancel: (_) => _resumeAutoScrollAfterTouch(),
              child: NestedScrollView(
                headerSliverBuilder:
                    (BuildContext context, bool innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      automaticallyImplyLeading: false,
                      backgroundColor:
                          metadata != null ? bloc.selectedTheme : Colors.white,
                      elevation: 0,
                      expandedHeight: isScrollingDown
                          ? (metadata != null ? 100.0 : 0.0)
                          : (metadata != null ? 156.0 : 56.0),
                      toolbarHeight: metadata != null
                          ? 100.0
                          : (isScrollingDown ? 0.0 : 56.0),
                      floating: false,
                      pinned: true,
                      flexibleSpace: Container(
                        color: metadata != null
                            ? bloc.selectedTheme
                            : Colors.white,
                        child: SafeArea(
                          bottom: false,
                          child: Stack(
                            children: [
                              // The Pinned Surah Header (Fills the pinned area)
                              if (metadata != null)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  height: 100,
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: SurahHeaderCard(
                                      key: ValueKey(metadata.index),
                                      metadata: metadata,
                                    ),
                                  ),
                                ),
                              // The Collapsible White Bar (Contains back button and title)
                              Positioned(
                                top: 0,
                                left: 0,
                                right: 0,
                                height: 56,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isScrollingDown ? 0.0 : 1.0,
                                  child: Container(
                                    color: Colors.white,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          icon: const Icon(Icons.arrow_back,
                                              color: Colors.black),
                                        ),
                                        Expanded(
                                          child: Center(
                                            child: Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 48.0),
                                              child: Text(
                                                '${widget.surahName}',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily:
                                                      bloc.arabicFontFamily,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
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
                    child: NotificationListener<ScrollEndNotification>(
                      onNotification: (scrollEnd) {
                        if (widget.saveLastRead &&
                            scrollEnd.metrics.axis == Axis.vertical) {
                          SavedPrefernces.updateLastReadOffset(
                              scrollEnd.metrics.pixels);
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _scrollViewController,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
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
            )));
  }
}
