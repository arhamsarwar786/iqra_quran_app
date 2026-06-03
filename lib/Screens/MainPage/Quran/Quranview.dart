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
import 'package:flutter_intro/flutter_intro.dart';
import '../../../Utils/utils.dart';

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
  final Map<int, GlobalKey> _ayahKeys = {};

  List<Widget> quranViewWidget = [];

  // Tracking for theme/font changes to trigger real-time re-renders
  double? _lastFontSize;
  String? _lastFontFamily;
  Color? _lastThemeColor;
  double _baseArabicFontSize = 30.0;

  viewMaker() async {
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final audioProvider = context.read<AudioProvider>();

    quranViewWidget.clear();
    List<InlineSpan> textSpanChildren = [];
    List<int> currentBatchAyatNumbers = [];
    bool isFirstAyat = true;

    // Helper to flush current spans into a widget
    void flush(bool isTarget) {
      if (textSpanChildren.isEmpty) return;

      GlobalKey? key;
      if (isTarget) {
        key = GlobalKey();
        _targetKey = key;
      }

      Widget rtWidget = RichText(
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
      );

      if (isFirstAyat) {
        quranViewWidget.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: IntroStepBuilder(
            group: 'quran_view',
            order: 4,
            getOverlayPosition: (
                {required offset, required screenSize, required size}) {
              return OverlayPosition(
                width: screenSize.width * 0.9,
                crossAxisAlignment: CrossAxisAlignment.center,
                top: offset.dy + size.height + 20,
                left: screenSize.width * 0.05,
              );
            },
            overlayBuilder: (params) => buildIntroOverlay(params,
                'Tap on any Ayat to open options for Tafseer, Audio, and Sharing.'),
            builder: (context, introKey) => Container(
              key: introKey,
              child: rtWidget,
            ),
          ),
        ));
        isFirstAyat = false;
      } else {
        quranViewWidget.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 8.0),
          child: rtWidget,
        ));
      }

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
      text = text.replaceAll(RegExp(r'[\u06D6-\u06ED\s]+$'), '');

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
            key: _ayahKeys[aya.ayatNumberInt] ??= GlobalKey(),
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            width: (bloc.arabicFontSize * 0.95).clamp(24.0, 36.0),
            height: (bloc.arabicFontSize * 0.95).clamp(24.0, 36.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTargetAyat
                    ? bloc.selectedTheme.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.35),
                width: 1.5,
              ),
            ),
            child: Text(
              aya.ayatNumber ?? '',
              style: TextStyle(
                fontSize: (bloc.arabicFontSize * 0.42).clamp(11.0, 17.0),
                fontWeight: FontWeight.bold,
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
    quranViewWidget.add(const SizedBox(height: 150));

    if (mounted) {
      setState(() {
        _lastFontSize = bloc.arabicFontSize;
        _lastFontFamily = bloc.arabicFontFamily;
        _lastThemeColor = bloc.selectedTheme;
      });
    }

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

    viewMaker().then((_) {
      // Jump to saved offset after content is loaded
      if (widget.initialScrollOffset != null &&
          widget.initialScrollOffset! > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollViewController != null &&
              _scrollViewController!.hasClients) {
            _scrollViewController!.jumpTo(widget.initialScrollOffset!);
          }
        });
      }
    });
    _scrollViewController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset ?? 0.0,
    );
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

    Future.delayed(const Duration(milliseconds: 300), () async {
      // SharedPreferences prefs = await SharedPreferences.getInstance();
      // bool introShown = prefs.getBool('quran_view_intro') ?? false;
      // if (!introShown) {
      if (mounted && _scaffoldKey.currentContext != null) {
        try {
          // Intro.of(_scaffoldKey.currentContext!).start(group: 'quran_view');
          // await prefs.setBool('quran_view_intro', true);
        } catch (_) {}
      }
      // }
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

  final GlobalKey _scaffoldKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final metadata = quranProvider.getSurahMetadata(widget.suratNumber ?? 0);

    // Detect theme/font changes and trigger re-render in real-time
    if (bloc.arabicFontSize != _lastFontSize ||
        bloc.arabicFontFamily != _lastFontFamily ||
        bloc.selectedTheme != _lastThemeColor) {
      Future.microtask(() => viewMaker());
    }

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

    return SafeArea(
      child: Intro(
        maskColor: bloc.selectedTheme.withOpacity(0.5),
        child: Scaffold(
          key: _scaffoldKey,
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
                    currentIndex:
                        audioProvider.currentAyahIndex != null ? 1 : 0,
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
                        if (isAutoScrolling) {
                          _stopAutoScroll();
                        } else {
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
                        }
                      } else if (index == 2) {
                        push(context, const SettingScreen());
                      }
                    },
                    items: [
                      BottomNavigationBarItem(
                        icon: IntroStepBuilder(
                          group: 'quran_view',
                          order: 1,
                          getOverlayPosition: (
                              {required offset,
                              required screenSize,
                              required size}) {
                            return OverlayPosition(
                              width: screenSize.width * 0.8,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              bottom: screenSize.height - offset.dy + 10,
                              left: screenSize.width * 0.1,
                            );
                          },
                          overlayBuilder: (params) => buildIntroOverlay(params,
                              'Change between Kanz-ul-Iman and Kanz-ul-Irfan translations.'),
                          builder: (context, key) => Padding(
                            key: key,
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        label: bloc.selectedTranslation == "irfan"
                            ? "Kanz-ul-Irfan"
                            : "Kanz-ul-Iman",
                      ),
                      BottomNavigationBarItem(
                        icon: IntroStepBuilder(
                          group: 'quran_view',
                          order: 2,
                          getOverlayPosition: (
                              {required offset,
                              required screenSize,
                              required size}) {
                            return OverlayPosition(
                              width: screenSize.width * 0.8,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              bottom: screenSize.height - offset.dy + 10,
                              left: screenSize.width * 0.1,
                            );
                          },
                          overlayBuilder: (params) => buildIntroOverlay(params,
                              'Auto-scroll the page hands-free while reciting or listening.'),
                          builder: (context, key) => Padding(
                            key: key,
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Icon(
                              isAutoScrolling
                                  ? Icons.stop_circle_rounded
                                  : Icons.fit_screen_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                        label: isAutoScrolling ? 'Stop' : 'Auto Scroll',
                      ),
                      BottomNavigationBarItem(
                        icon: IntroStepBuilder(
                          group: 'quran_view',
                          order: 3,
                          getOverlayPosition: (
                              {required offset,
                              required screenSize,
                              required size}) {
                            return OverlayPosition(
                              width: screenSize.width * 0.8,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              bottom: screenSize.height - offset.dy + 10,
                              left: screenSize.width * 0.1,
                            );
                          },
                          overlayBuilder: (params) => buildIntroOverlay(params,
                              'Customize font size, family, and translation language.'),
                          builder: (context, key) => Padding(
                            key: key,
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: const Icon(
                              Icons.settings_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
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
            onScaleStart: (details) {
              _baseArabicFontSize = bloc.arabicFontSize;
            },
            onScaleUpdate: (details) {
              if (details.scale != 1.0) {
                double newSize =
                    (_baseArabicFontSize * details.scale).clamp(20.0, 60.0);
                bloc.changeArabicFont(newSize);
              }
            },
            child: Stack(
              children: [
                Listener(
                  onPointerDown: (_) => _pauseAutoScrollForTouch(),
                  onPointerUp: (_) => _resumeAutoScrollAfterTouch(),
                  onPointerCancel: (_) => _resumeAutoScrollAfterTouch(),
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollEndNotification) {
                        if (widget.saveLastRead) {
                          _updateLastRead(notification.metrics.pixels);
                        }
                      }
                      return false;
                    },
                    child: NestedScrollView(
                      headerSliverBuilder:
                          (BuildContext context, bool innerBoxIsScrolled) {
                        return [
                          SliverAppBar(
                            automaticallyImplyLeading: false,
                            backgroundColor: metadata != null
                                ? bloc.selectedTheme
                                : Colors.white,
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
                          padding: const EdgeInsets.only(top: 4, bottom: 0),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: SingleChildScrollView(
                              controller: _scrollViewController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: Container(
                                padding: const EdgeInsets.only(
                                    left: 12, right: 12, top: 10, bottom: 10),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
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
        ),
      ),
    );
  }

  void _updateLastRead(double pixels) {
    int? topAyah;
    double minDiff = double.infinity;

    for (var entry in _ayahKeys.entries) {
      final context = entry.value.currentContext;
      if (context != null) {
        final box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero,
            ancestor: this.context.findRenderObject());
        // Find the ayat closest to top
        double diff = position.dy.abs();
        if (diff < minDiff) {
          minDiff = diff;
          topAyah = entry.key;
        }
      }
    }

    SavedPrefernces.updateLastReadOffset(pixels, ayatNumber: topAyah);
  }
}
