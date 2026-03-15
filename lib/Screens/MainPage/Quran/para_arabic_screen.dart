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
import '../../../Provider/audio_provider.dart';

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
  bool isScrollingDown = false;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false;
  double autoScrollSpeed = 1.0;
  Map<String, GlobalKey> surahHeaderKeys = {};
  GlobalKey? _targetKey;
  int? _highlightedAyah;
  String? _lastRecitedId;
  AudioProvider? _audioProvider;
  List<Widget> paraArabicScreenWidget = [];

  // Tracking for theme/font changes to trigger real-time re-renders
  double? _lastFontSize;
  String? _lastFontFamily;
  Color? _lastThemeColor;
  List<Aya> listAyat = [];
  SurahMetadata? firstSurahMetadata;
  SurahMetadata? currentSurahMetadata;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider = Provider.of<AudioProvider>(context, listen: false);
  }

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

  void viewMaker() async {
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    if (listAyat.isEmpty) return;

    paraArabicScreenWidget.clear();
    // surahHeaderKeys.clear(); // Removed to allow persistence across build/highlight cycles
    firstSurahMetadata = null;

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

    // audioProvider is already available via context.read or watch
    final audioProvider = context.read<AudioProvider>();

    for (var i = 0; i < listAyat.length; i++) {
      var aya = listAyat[i];
      final int ayaSurahId = int.tryParse(aya.surahId ?? "0") ?? 0;

      // Check if this ayah is actually the one currently reciting
      bool isReciting = audioProvider.currentAyahId != null &&
          audioProvider.currentAyahId == aya.ayatId;

      final bool isTargetAya = isReciting ||
          (_highlightedAyah != null &&
              aya.ayatNumberInt == _highlightedAyah &&
              ayaSurahId == widget.targetSurahNumber);

      // 1. Surah Change Detection
      if (currentSurahId != aya.surahId) {
        flush(false);
        currentSurahId = aya.surahId;
        final metadata = quranProvider.getSurahMetadata(ayaSurahId);
        if (metadata != null) {
          // Reuse existing key to help Flutter maintain state
          final key = surahHeaderKeys[aya.surahId!] ?? GlobalKey();
          surahHeaderKeys[aya.surahId!] = key;

          if (firstSurahMetadata == null) {
            firstSurahMetadata = metadata;
            currentSurahMetadata = metadata;
            // Invisible tracker for the first surah of the Juz
            paraArabicScreenWidget.add(_KeepAliveWrapper(
              child: SizedBox(key: key, height: 0),
            ));
          } else {
            paraArabicScreenWidget.add(_KeepAliveWrapper(
              child: SurahHeaderCard(
                key: key,
                metadata: metadata,
              ),
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
                  context, listAyat, listAyat.indexOf(aya), bloc,
                  showPlayButton: false);
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
    if (mounted) {
      setState(() {
        _lastFontSize = bloc.arabicFontSize;
        _lastFontFamily = bloc.arabicFontFamily;
        _lastThemeColor = bloc.selectedTheme;
      });
    }

    // After the list is built and rendered, ensure the header shows the correct Surah
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateCurrentSurah();

      if (_targetKey != null) {
        final ctx = _targetKey!.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            alignment: 0.4, // Keep verse clearly below the header
            curve: Curves.easeInOut,
          );
        }
      }
    });
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

  // Removed buggy nudge scroll logic

  void _updateCurrentSurah() {
    if (firstSurahMetadata == null || listAyat.isEmpty) return;

    final qProvider = context.read<QuranDataProvider>();
    SurahMetadata? bestMatch = firstSurahMetadata;

    double statusBarHeight = MediaQuery.of(context).padding.top;
    double threshold = statusBarHeight + 110.0;
    bool foundInView = false;

    // 1. Try tracking via GlobalKeys of headers/trackers
    for (var entry in surahHeaderKeys.entries) {
      final context = entry.value.currentContext;
      if (context != null) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final position = box.localToGlobal(Offset.zero).dy;

        if (position <= threshold) {
          final metadata =
              qProvider.getSurahMetadata(int.tryParse(entry.key) ?? 0);
          if (metadata != null) {
            bestMatch = metadata;
            foundInView = true;
          }
        } else {
          break; // Stop at first header below threshold
        }
      }
    }

    // 2. Fallback: If we didn't find a currently built header that passed threshold,
    // but we are scrolled down, use percentage of the list to estimate the surah.
    // This handles the case where long surahs cause headers to be disposed.
    if (!foundInView && _scrollViewController!.hasClients) {
      final offset = _scrollViewController!.offset;
      final maxScroll = _scrollViewController!.position.maxScrollExtent;

      if (offset > 500 && maxScroll > 0) {
        double progress = (offset / maxScroll).clamp(0.0, 1.0);
        int targetAyahIndex = (progress * (listAyat.length - 1)).toInt();
        final estimatedAyah = listAyat[targetAyahIndex];
        final surahId = int.tryParse(estimatedAyah.surahId ?? "0") ?? 0;
        final metadata = qProvider.getSurahMetadata(surahId);
        if (metadata != null) {
          bestMatch = metadata;
        }
      }
    }

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
    // Stop audio when moving back from the screen
    _audioProvider?.stopPlayback();
    _scrollViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();

    // Detect theme/font changes and trigger re-render in real-time
    if (bloc.arabicFontSize != _lastFontSize ||
        bloc.arabicFontFamily != _lastFontFamily ||
        bloc.selectedTheme != _lastThemeColor) {
      Future.microtask(() => viewMaker());
    }

    // Sync highlighting with audio
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
                        backgroundColor: currentSurahMetadata != null
                            ? bloc.selectedTheme
                            : Colors.white,
                        elevation: 0,
                        expandedHeight: isScrollingDown
                            ? (currentSurahMetadata != null ? 100.0 : 0.0)
                            : (currentSurahMetadata != null ? 156.0 : 56.0),
                        toolbarHeight: currentSurahMetadata != null
                            ? 100.0
                            : (isScrollingDown ? 0.0 : 56.0),
                        floating: false,
                        pinned: true,
                        flexibleSpace: CompleteQuranHeader(
                          title:
                              widget.parahname ?? 'Para ${widget.parahCount}',
                          metadata: currentSurahMetadata,
                          isScrollingDown: isScrollingDown,
                        ),
                      ),
                    ];
                  },
                  body: SizedBox.expand(
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
                            physics: const AlwaysScrollableScrollPhysics(),
                            cacheExtent: 5000,
                            slivers: [
                              SliverPadding(
                                padding: const EdgeInsets.only(
                                    left: 5, right: 5, bottom: 30, top: 10),
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
                  ),
                ),
              ),
            ],
          ),
        ));
  }
}

/// A wrapper to keep the trackers and headers alive in the lazy-loading SliverList.
/// This ensures their GlobalKey contexts are not destroyed when scrolled far away.
class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }

  @override
  bool get wantKeepAlive => true;
}
