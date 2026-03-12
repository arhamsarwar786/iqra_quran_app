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
import '../../../Provider/audio_provider.dart';
import '../../../Widgets/audio_controller_overlay.dart';

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
  bool isScrollingDown = false;
  GlobalKey? _targetKey;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false;
  double autoScrollSpeed = 1.0;
  String? _lastRecitedId;
  AudioProvider? _audioProvider;

  List<Widget> quranViewWidget = [];

  viewMaker() async {
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final audioProvider = context.read<AudioProvider>();

    quranViewWidget.clear();
    List<InlineSpan> textSpanChildren = [];
    List<int> currentBatchAyatNumbers = [];

    // Helper to flush current spans into a widget
    void flush(bool isTarget) {
      if (textSpanChildren.isEmpty) return;

      GlobalKey? key;
      if (isTarget) {
        key = GlobalKey();
        _targetKey = key;
      }

      quranViewWidget.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: RichText(
          key: key,
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
      currentBatchAyatNumbers.clear();
    }

    for (var i = 0; i < listAyat.length; i++) {
      var aya = listAyat[i];
      if (aya.ayatNumber == "0") continue;

      // Check if this ayah is the one being recited using unique ID
      bool isReciting = audioProvider.currentAyahId != null &&
          audioProvider.currentAyahId == aya.ayatId;

      // Fallback: use targetAyatNumber for initial deep-linking/highlights
      bool isTargetAyat = isReciting ||
          (_highlightedAyah != null && aya.ayatNumberInt == _highlightedAyah);

      if (isTargetAyat) {
        flush(false);
      }

      currentBatchAyatNumbers.add(aya.ayatNumberInt);

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
                  context, listAyat, listAyat.indexOf(aya), bloc,
                  showPlayButton: true);
            },
        ),
      );

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

      if (isTargetAyat) {
        flush(true);
      }

      bool isSajda = aya.hasSajda;
      bool isRuoEnd = aya.hasRuko;
      bool isManzil = aya.manzil != null;
      bool isArba = aya.hasArba;
      bool isNisf = aya.hasNisf;
      bool isSalsa = aya.hasSalsa;

      if (isSajda || isRuoEnd || isManzil || isArba || isNisf || isSalsa) {
        flush(false);

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
    } // Final flush
    if (textSpanChildren.isNotEmpty) {
      flush(false);
    }

    if (mounted) setState(() {});

    if (_targetKey != null) {
      // Trigger scroll precisely after build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _targetKey!.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.4, // Keep verse clearly below the header
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  int? _highlightedAyah;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
  }

  @override
  void initState() {
    super.initState();
    // Special case for Al-Fatiha: No need to select the first ayat initially
    if (widget.suratNumber == 1 &&
        (widget.targetAyatNumber == null || widget.targetAyatNumber == 0)) {
      _highlightedAyah = null;
    } else {
      _highlightedAyah = widget.targetAyatNumber;
    }
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
          setState(() {});
        }
      }

      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          isScrollingDown = false;
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
          isScrollingDown = false;
        });
      }
    });
    setState(() {
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
      isScrollingDown = false;
    });
  }

  @override
  void dispose() {
    // Stop audio when moving back from the screen
    _audioProvider?.stopPlayback();
    _scrollViewController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final metadata = quranProvider.getSurahMetadata(widget.suratNumber ?? 0);

    // Sync highlighting with audio using global ayatId
    if (audioProvider.currentAyahId != _lastRecitedId) {
      _lastRecitedId = audioProvider.currentAyahId;

      // Clear manual highlight when audio stops or moves to next
      if (_lastRecitedId == null) {
        _highlightedAyah = null;
      }

      // Schedule re-render to highlight and scroll
      Future.microtask(() => viewMaker());
    }

    return Scaffold(
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
                unselectedLabelStyle: const TextStyle(color: Colors.white),
                currentIndex: audioProvider.currentAyahIndex != null ? 1 : 0,
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
                  }
                  // else if (index == 1) {
                  //   if (audioProvider.currentAyahIndex != null) {
                  //     if (audioProvider.isPlaying) {
                  //       audioProvider.pausePlayback();
                  //     } else {
                  //       audioProvider.resumePlayback();
                  //     }
                  //   } else {
                  //     // Start playback from the beginning of the surah using ayatId
                  //     audioProvider.startSurahPlayback(
                  //         context, listAyat, widget.surahName ?? "Surah",
                  //         startAyatId: listAyat.isNotEmpty
                  //             ? listAyat
                  //                 .firstWhere((a) => a.ayatNumber != "0",
                  //                     orElse: () => listAyat.first)
                  //                 .ayatId
                  //             : null);
                  //   }
                  // }
                  else if (index == 1) {
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
                  // BottomNavigationBarItem(
                  //   icon: Padding(
                  //     padding: const EdgeInsets.only(bottom: 4.0),
                  //     child: Icon(
                  //       audioProvider.currentAyahIndex != null
                  //           ? (audioProvider.isPlaying
                  //               ? Icons.pause_circle_filled_rounded
                  //               : Icons.play_circle_filled_rounded)
                  //           : Icons.play_circle_outline_rounded,
                  //       color: Colors.white,
                  //       size: 26,
                  //     ),
                  //   ),
                  //   label: audioProvider.currentAyahIndex != null
                  //       ? (audioProvider.isPlaying ? 'Pause' : 'Resume')
                  //       : 'Play Audio',
                  // ),
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
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            isScrollingDown = !isScrollingDown;
          });
        },
        child: Stack(
          children: [
            Listener(
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
                      flexibleSpace: CompleteQuranHeader(
                        title: widget.surahName ?? '',
                        metadata: metadata,
                        isScrollingDown: isScrollingDown,
                      ),
                    ),
                  ];
                },
                body: SizedBox.expand(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.only(top: 4, bottom: 20),
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
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
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
              ),
            ),
            const QuranAudioOverlay(),
          ],
        ),
      ),
    );
  }
}
