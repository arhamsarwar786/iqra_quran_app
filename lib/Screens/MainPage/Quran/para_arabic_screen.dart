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
import '../../../Helper/preference/saved_preferences.dart';
import '../Drawer/setting_screen.dart';
import 'translation/parah_translation_screen.dart';

class ParaArabicScreen extends StatefulWidget {
  final String? parahCount;
  final int? ayatInPara;
  final ParaModel.Para? para;
  final String? parahname;
  final int? targetAyatNumber;
  final int? targetSurahNumber;
  final double? initialScrollOffset;
  final bool saveLastRead;

  const ParaArabicScreen({
    super.key,
    this.para,
    this.ayatInPara,
    this.parahCount,
    this.parahname,
    this.targetAyatNumber,
    this.targetSurahNumber,
    this.initialScrollOffset,
    this.saveLastRead = true,
  });

  @override
  State<ParaArabicScreen> createState() => _ParaArabicScreenState();
}

class _ParaArabicScreenState extends State<ParaArabicScreen> {
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool isScrollingDown = true;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false;
  double autoScrollSpeed = 1.0;

  List<Widget> paraArabicScreenWidget = [];
  List<Aya> listAyat = [];
  SurahMetadata? firstSurahMetadata;
  SurahMetadata? currentSurahMetadata;
  Map<String, GlobalKey> surahHeaderKeys = {};
  bool _hasInitialScrolled = false;
  GlobalKey? _targetKey;
  int? _highlightedAyah;

  @override
  void initState() {
    super.initState();
    _highlightedAyah = widget.targetAyatNumber;

    if (widget.saveLastRead) {
      SavedPrefernces.setLastRead({
        "type": "para",
        "id": widget.parahCount,
        "name": widget.parahname,
        "count": widget.ayatInPara?.toString(),
      });
    }

    loadParaView().then((val) {
      listAyat = List<Aya>.from(val);
      viewMaker();
    });

    _scrollViewController = ScrollController();
    _scrollViewController!.addListener(() {
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.reverse) {
        if (!isScrollingDown) {
          setState(() {
            isScrollingDown = true;
          });
        }
      }
      if (_scrollViewController!.position.userScrollDirection ==
          ScrollDirection.forward) {
        if (isScrollingDown) {
          setState(() {
            isScrollingDown = false;
          });
        }
      }
      _updateCurrentSurah();
    });
  }

  Future<List> loadParaView() async {
    final provider = context.read<QuranDataProvider>();
    if (!provider.isLoaded) {
      await provider.loadQuranData();
    }
    String paraId = widget.parahCount.toString();
    return provider.getAyatsByPara(int.tryParse(paraId) ?? 0);
  }

  /// Refactored view maker for clean and robust verse matching
  void viewMaker() async {
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();

    paraArabicScreenWidget.clear();
    surahHeaderKeys.clear();
    _targetKey = null;
    firstSurahMetadata = null;
    currentSurahMetadata = null;

    if (listAyat.isEmpty) return;

    List<InlineSpan> currentSpans = [];
    String? currentSurahId;

    // Helper to flush blocks and assign the target key precisely
    void flush(bool hasTarget) {
      if (currentSpans.isEmpty) return;

      GlobalKey? key;
      if (hasTarget) {
        key = GlobalKey();
        _targetKey = key;
      }

      paraArabicScreenWidget.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: RichText(
          key: key,
          textAlign: TextAlign
              .center, // Center alignment looks much better for Quranic text in Flutter
          text: TextSpan(
            children: List<InlineSpan>.from(currentSpans),
            style: TextStyle(
              fontSize: bloc.arabicFontSize,
              fontFamily: bloc.arabicFontFamily,
              color: Colors.black,
              height: 1.8,
            ),
          ),
        ),
      ));
      currentSpans.clear();
    }

    for (var aya in listAyat) {
      final int ayaSurahId = int.tryParse(aya.surahId ?? "0") ?? 0;
      final bool isTargetAya = _highlightedAyah != null &&
          aya.ayatNumberInt == _highlightedAyah &&
          ayaSurahId == widget.targetSurahNumber;

      // 1. Surah Change Detection
      if (currentSurahId != aya.surahId) {
        flush(false);
        currentSurahId = aya.surahId;
        final metadata = quranProvider.getSurahMetadata(ayaSurahId);
        if (metadata != null) {
          if (firstSurahMetadata == null) {
            firstSurahMetadata = metadata;
            currentSurahMetadata = metadata;
          } else {
            final key = GlobalKey();
            surahHeaderKeys[aya.surahId!] = key;
            paraArabicScreenWidget.add(SurahHeaderCard(
              key: key,
              metadata: metadata,
            ));
          }
        }
      }

      if (aya.ayatNumber == "0") continue; // Skip Bismillah added in card

      // 2. Isolate target verse by flushing before it
      if (isTargetAya) {
        flush(false);
      }

      // 3. Clean and add verse text span
      String text = aya.arabicText.trim();
      // Remove trailing bracketed numbers if they exist in the text
      text = text.replaceAll(RegExp(r'\s*\(\d+\)\s*$'), '');

      currentSpans.add(
        TextSpan(
          text: "$text ",
          style: TextStyle(
            color: isTargetAya ? bloc.selectedTheme : Colors.black,
            fontWeight: isTargetAya ? FontWeight.w700 : FontWeight.normal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              SHEET.bottomSheetPreview(
                  context, listAyat, listAyat.indexOf(aya), bloc);
            },
        ),
      );

      // Append decorative Verse Marker
      currentSpans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isTargetAya
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
                color: isTargetAya ? bloc.selectedTheme : Colors.black54,
              ),
            ),
          ),
        ),
      );

      // 4. Split after target or signs
      bool hasSplitSign = aya.hasSajda ||
          aya.manzil != null ||
          aya.hasRuko ||
          aya.hasArba ||
          aya.hasNisf ||
          aya.hasSalsa;

      if (hasSplitSign || isTargetAya) {
        flush(isTargetAya);

        // Add sign widgets
        if (hasSplitSign) {
          _addSignWidget(aya, quranProvider);
        }
      }
    }

    flush(false); // Flush final block
    setState(() {});

    _initiateScroll();
  }

  void _addSignWidget(Aya aya, QuranDataProvider quranProvider) {
    String mainSign = "";
    String? displayLabel;
    String? topNum, midNum, botNum;

    if (aya.hasRuko) {
      mainSign = "ع";
      if (aya.hasArba) displayLabel = "الربع";
      if (aya.hasNisf) displayLabel = "النصف";
      if (aya.hasSalsa) displayLabel = "الثلاثة";
      if (aya.hasSajda) {
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
    } else if (aya.hasSajda) {
      mainSign = "السجدة";
    } else if (aya.manzil != null) {
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

  void _initiateScroll() {
    if (widget.initialScrollOffset != null && !_hasInitialScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollViewController!.hasClients) {
          _scrollViewController!.jumpTo(widget.initialScrollOffset!);
        }
        _hasInitialScrolled = true;
      });
    } else if (_targetKey != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollViewController != null &&
            _scrollViewController!.hasClients) {
          int targetIndex = paraArabicScreenWidget.indexWhere((w) {
            return w.key == _targetKey;
          });

          if (targetIndex != -1) {
            // Jump to approximate area to force SliverList to build children
            double jumpPos = (targetIndex * 150.0)
                .clamp(0, _scrollViewController!.position.maxScrollExtent);
            _scrollViewController!.jumpTo(jumpPos);
          }

          _scrollRetryCount = 0;
          Future.delayed(const Duration(milliseconds: 200), () {
            if (mounted) _scrollToTarget(Duration.zero);
          });
        }
      });
    }
  }

  int _scrollRetryCount = 0;
  static const int _maxScrollRetries = 50;

  void _scrollToTarget(Duration _) {
    if (!mounted || _targetKey == null) return;
    final ctx = _targetKey!.currentContext;
    if (ctx != null) {
      final renderObject = ctx.findRenderObject() as RenderBox?;
      if (renderObject != null &&
          renderObject.hasSize &&
          renderObject.size.height > 0) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 600),
          alignment: 0.5,
        );
      } else if (_scrollRetryCount < _maxScrollRetries) {
        _scrollRetryCount++;
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) _scrollToTarget(Duration.zero);
        });
      }
    } else if (_scrollRetryCount < _maxScrollRetries) {
      _scrollRetryCount++;
      // Search Step: Nudge scroll to trigger more child building if ctx is null
      double nextPos = (_scrollViewController!.offset + 200)
          .clamp(0, _scrollViewController!.position.maxScrollExtent);
      _scrollViewController!.jumpTo(nextPos);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _scrollToTarget(Duration.zero);
      });
    }
  }

  void _updateCurrentSurah() {
    if (firstSurahMetadata == null) return;
    SurahMetadata? bestMatch = firstSurahMetadata;
    double threshold = 200.0;

    surahHeaderKeys.forEach((surahId, key) {
      final context = key.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;
        if (position <= threshold) {
          final qProvider = context.read<QuranDataProvider>();
          final metadata =
              qProvider.getSurahMetadata(int.tryParse(surahId) ?? 0);
          if (metadata != null) bestMatch = metadata;
        }
      }
    });

    if (currentSurahMetadata?.index != bestMatch?.index) {
      setState(() {
        currentSurahMetadata = bestMatch;
      });
    }
  }

  void _startAutoScroll() {
    if (!isAutoScrolling) return;
    double currentPixels = _scrollViewController!.position.pixels;
    double maxPixels = _scrollViewController!.position.maxScrollExtent;
    double remainingDistance = maxPixels - currentPixels;

    if (remainingDistance <= 0) {
      setState(() {
        isAutoScrolling = false;
        isScrollingDown = false;
      });
      return;
    }

    double pixelsPerSecond = 30.0 * autoScrollSpeed;
    double durationSeconds = remainingDistance / pixelsPerSecond;

    _scrollViewController!
        .animateTo(
      maxPixels,
      duration: Duration(milliseconds: (durationSeconds * 1000).toInt()),
      curve: Curves.linear,
    )
        .then((_) {
      if (isAutoScrolling &&
          _scrollViewController!.position.pixels >=
              _scrollViewController!.position.maxScrollExtent) {
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
    _scrollViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
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
                    currentIndex: 0,
                    type: BottomNavigationBarType.fixed,
                    onTap: (index) {
                      if (index == 0) {
                        push(
                            context,
                            ParahTranslationScreen(
                              parahCount: widget.parahCount,
                              parahname: widget.parahname,
                              ayatInPara: widget.ayatInPara,
                              para: widget.para,
                              ayatList: listAyat,
                            ));
                      } else if (index == 1) {
                        showDialog(
                          context: context,
                          builder: (context) => AutoScrollSpeedDialog(
                            currentSpeedFactor: autoScrollSpeed,
                            isScrolling: isAutoScrolling,
                            onSpeedChanged: (val) {
                              setState(() => autoScrollSpeed = val);
                              if (isAutoScrolling) {
                                _stopAutoScroll();
                                _startAutoScroll();
                              }
                            },
                            onStart: () {
                              setState(() => isAutoScrolling = true);
                              _startAutoScroll();
                            },
                            onStop: () => _stopAutoScroll(),
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
                          child: Icon(Icons.menu_book_rounded,
                              color: Colors.white, size: 26),
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
                              size: 26),
                        ),
                        label: isAutoScrolling ? "Stop" : "Auto Scroll",
                      ),
                      const BottomNavigationBarItem(
                        icon: Padding(
                          padding: EdgeInsets.only(bottom: 4.0),
                          child: Icon(Icons.settings_rounded,
                              color: Colors.white, size: 26),
                        ),
                        label: "Setting",
                      ),
                    ],
                  ),
                ),
          body: Listener(
            onPointerDown: (_) => _pauseAutoScrollForTouch(),
            onPointerUp: (_) => _resumeAutoScrollAfterTouch(),
            onPointerCancel: (_) => _resumeAutoScrollAfterTouch(),
            child: Container(
              color: Colors.white,
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
                  child: CustomScrollView(
                    controller: _scrollViewController,
                    cacheExtent: 5000,
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        expandedHeight: isScrollingDown
                            ? (currentSurahMetadata != null ? 100.0 : 0.0)
                            : (currentSurahMetadata != null ? 156.0 : 56.0),
                        toolbarHeight: currentSurahMetadata != null
                            ? 100.0
                            : (isScrollingDown ? 0.0 : 56.0),
                        floating: false,
                        pinned: true,
                        flexibleSpace: Container(
                          color: currentSurahMetadata != null
                              ? bloc.selectedTheme
                              : Colors.white,
                          child: SafeArea(
                            bottom: false,
                            child: Stack(
                              children: [
                                // The Pinned Surah Header (Fills the pinned area)
                                if (currentSurahMetadata != null)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    height: 100,
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: SurahHeaderCard(
                                        key: ValueKey(
                                            currentSurahMetadata!.index),
                                        metadata: currentSurahMetadata!,
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
                                                  widget.parahname ??
                                                      'Para ${widget.parahCount}',
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
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate(
                            paraArabicScreenWidget,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ));
    }));
  }
}
