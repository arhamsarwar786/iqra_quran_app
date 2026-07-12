// ignore_for_file: file_names

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:arabic_numbers/arabic_numbers.dart';
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
import 'package:iqra/Helper/favourite.dart';
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
  final Map<String, GlobalKey> _ayahKeys = {};

  // Tracking for theme/font changes to trigger real-time re-renders
  double _pinchStartFontSize = 30.0;
  double? _pinchStartDistance;
  bool _isPinching = false;
  final Map<int, Offset> _activePointers = {};
  ThemeProvider? _themeProvider;
  DateTime? _lastPinchRebuild;
  int _viewMakerGeneration = 0;
  List<Aya> listAyat = [];
  SurahMetadata? firstSurahMetadata;
  SurahMetadata? currentSurahMetadata;

  Set<String> bookmarkedAyats = {};

  Future<void> _loadAyatBookmarks() async {
    final data = await SavedPreferences.getBookmarkedAyats();
    if (data != null && mounted) {
      setState(() {
        bookmarkedAyats = Set<String>.from(data);
      });
    }
  }

  Future<void> _toggleAyatBookmark(String key) async {
    if (bookmarkedAyats.contains(key)) {
      bookmarkedAyats.remove(key);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayat removed from bookmarks', textAlign: TextAlign.center),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      bookmarkedAyats.add(key);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayat added to bookmarks', textAlign: TextAlign.center),
          duration: Duration(seconds: 1),
        ),
      );
    }
    setState(() {});
    await SavedPreferences.setBookmarkedAyats(bookmarkedAyats.toList());
    viewMaker();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _audioProvider ??= Provider.of<AudioProvider>(context, listen: false);

    final theme = context.read<ThemeProvider>();
    if (_themeProvider != theme) {
      _themeProvider?.removeListener(_onThemeChanged);
      _themeProvider = theme;
      _themeProvider!.addListener(_onThemeChanged);
    }
  }

  void _onThemeChanged() {
    if (!mounted || listAyat.isEmpty) return;

    if (_isPinching) {
      final now = DateTime.now();
      if (_lastPinchRebuild != null &&
          now.difference(_lastPinchRebuild!) <
              const Duration(milliseconds: 120)) {
        return;
      }
      _lastPinchRebuild = now;
    }

    _rebuildParaContent();
  }

  Future<void> _rebuildParaContent() async {
    final controller = _scrollViewController;
    final offset = controller != null && controller.hasClients
        ? controller.offset
        : 0.0;
    await viewMaker();
    if (!mounted) return;
    if (controller != null && controller.hasClients) {
      final max = controller.position.maxScrollExtent;
      controller.jumpTo(offset.clamp(0.0, max));
    }
  }

  Future<void> _openSettings() async {
    await push(context, const SettingScreen());
    if (!mounted) return;
    await _rebuildParaContent();
  }

  double _pointerDistance() {
    final positions = _activePointers.values.toList();
    if (positions.length < 2) return 0;
    return (positions[0] - positions[1]).distance;
  }

  void _handlePointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.position;
    _pauseAutoScrollForTouch();

    if (_activePointers.length == 2) {
      _pinchStartDistance = _pointerDistance();
      _pinchStartFontSize = context.read<ThemeProvider>().arabicFontSize;
      setState(() => _isPinching = true);
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    _activePointers[event.pointer] = event.position;

    if (_activePointers.length >= 2 &&
        _pinchStartDistance != null &&
        _pinchStartDistance! > 0) {
      final scale = _pointerDistance() / _pinchStartDistance!;
      final newSize = (_pinchStartFontSize * scale).clamp(20.0, 60.0);
      context.read<ThemeProvider>().changeArabicFont(newSize);
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _activePointers.remove(event.pointer);

    if (_activePointers.length < 2) {
      _pinchStartDistance = null;
      if (_isPinching) {
        setState(() => _isPinching = false);
        _lastPinchRebuild = null;
        _rebuildParaContent();
      }
    }

    if (_activePointers.isEmpty) {
      _resumeAutoScrollAfterTouch();
    }
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
      _loadAyatBookmarks().then((_) {
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
      });
    });

    _scrollViewController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset ?? 0.0,
    );
    _scrollViewController!.addListener(() {
      final position = _scrollViewController!.position;
      if (position.pixels <= 8) {
        if (isScrollingDown) {
          setState(() => isScrollingDown = false);
        }
      } else if (position.userScrollDirection == ScrollDirection.reverse) {
        if (!isScrollingDown) {
          setState(() => isScrollingDown = true);
        }
      } else if (position.userScrollDirection == ScrollDirection.forward) {
        if (isScrollingDown) {
          setState(() => isScrollingDown = false);
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

  Future<void> viewMaker() async {
    final generation = ++_viewMakerGeneration;
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    if (listAyat.isEmpty) return;

    final builtWidgets = <Widget>[];
    _ayahKeys.clear();
    final savedFirstSurahMetadata = firstSurahMetadata;

    List<Widget> currentSpans = [];
    String? currentSurahId;

    var isFirstSurahHeaderPending = savedFirstSurahMetadata == null;

    // Helper to flush blocks and assign the target key precisely
    void flush(bool hasTarget) {
      if (currentSpans.isEmpty) return;

      GlobalKey? key;
      if (hasTarget) {
        key = GlobalKey();
        _targetKey = key;
      }

      builtWidgets.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
        child: Container(
          key: key,
          width: double.infinity,
          alignment: Alignment.center,
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            textDirection: TextDirection.rtl,
            spacing: (bloc.arabicFontSize * 0.18).clamp(5.0, 9.0),
            runSpacing: (bloc.arabicFontSize * 0.45).clamp(12.0, 22.0),
            children: List<Widget>.from(currentSpans),
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

          if (isFirstSurahHeaderPending) {
            firstSurahMetadata = metadata;
            currentSurahMetadata = metadata;
            isFirstSurahHeaderPending = false;
            // Invisible tracker for the first surah of the Juz
            builtWidgets.add(_KeepAliveWrapper(
              child: SizedBox(key: key, height: 0),
            ));
          } else {
            builtWidgets.add(_KeepAliveWrapper(
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
      text = text.replaceAll(RegExp(r'[\u06D6-\u06ED\s]+$'), '');

      // Split verse text into words for Wrap layout
      final List<String> words = text.split(RegExp(r'\s+'));
      for (final word in words) {
        if (word.trim().isEmpty) continue;
        currentSpans.add(
          GestureDetector(
            onTap: () {
              SHEET.bottomSheetPreview(
                  context, listAyat, listAyat.indexOf(aya), bloc,
                  showPlayButton: false);
            },
            child: Text(
              word,
              style: TextStyle(
                fontSize: bloc.arabicFontSize,
                fontFamily: bloc.arabicFontFamily,
                color: isTargetAya ? bloc.selectedTheme : Colors.black,
                fontWeight:
                    isTargetAya ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }

      // Bookmark-able verse number circle
      final String bookmarkKey = "${aya.surahId}_${aya.ayatNumber}";
      final bool isBookmarked = bookmarkedAyats.contains(bookmarkKey);
      currentSpans.add(
        GestureDetector(
          onTap: () => _toggleAyatBookmark(bookmarkKey),
          child: Container(
            key: _ayahKeys["${aya.surahId}_${aya.ayatNumber}"] ??= GlobalKey(),
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            width: (bloc.arabicFontSize * 0.95).clamp(24.0, 36.0),
            height: (bloc.arabicFontSize * 0.95).clamp(24.0, 36.0),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBookmarked
                  ? bloc.selectedTheme.withOpacity(0.12)
                  : Colors.transparent,
              border: Border.all(
                color: isBookmarked
                    ? bloc.selectedTheme
                    : (isTargetAya
                        ? bloc.selectedTheme.withOpacity(0.5)
                        : Colors.grey.withOpacity(0.35)),
                width: 1.5,
              ),
            ),
            child: Text(
              aya.ayatNumber ?? '',
              style: TextStyle(
                fontSize: (bloc.arabicFontSize * 0.42).clamp(11.0, 17.0),
                fontWeight: FontWeight.bold,
                color: isBookmarked
                    ? bloc.selectedTheme
                    : (isTargetAya ? bloc.selectedTheme : Colors.black54),
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
          _addSignWidget(aya, quranProvider, builtWidgets);
        }
      }
    }

    flush(false); // Flush final block
    builtWidgets.add(const SizedBox(height: 150));

    if (!mounted || generation != _viewMakerGeneration) return;

    setState(() {
      paraArabicScreenWidget = builtWidgets;
    });

    // After the list is built and rendered, ensure the header shows the correct Surah
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _updateCurrentSurah();

      if (_targetKey != null) {
        final ctx = _targetKey!.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 350),
            alignment: 0.12,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            curve: Curves.easeInOut,
          );
        }
      }
    });
  }

  void _addSignWidget(
      Aya aya, QuranDataProvider quranProvider, List<Widget> target) {
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
      target.add(QuranSignWidget(
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
    _themeProvider?.removeListener(_onThemeChanged);
    // Stop audio when moving back from the screen
    _audioProvider?.stopPlayback();
    _scrollViewController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.watch<ThemeProvider>();
    final audioProvider = context.watch<AudioProvider>();

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
                        if (isAutoScrolling) {
                          _stopAutoScroll();
                        } else {
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
                        }
                      } else if (index == 2) {
                        _openSettings();
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
                Column(
                  children: [
                    CompleteQuranHeader(
                      title:
                          widget.parahname ?? 'Para ${widget.parahCount}',
                      metadata: currentSurahMetadata,
                      isScrollingDown: isScrollingDown,
                    ),
                    Expanded(
                      child: Listener(
                        onPointerDown: _handlePointerDown,
                        onPointerMove: _handlePointerMove,
                        onPointerUp: _handlePointerUp,
                        onPointerCancel: _handlePointerUp,
                        child: NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollEndNotification) {
                              if (widget.saveLastRead) {
                                _updateLastRead(notification.metrics.pixels);
                              }
                            }
                            return false;
                          },
                          child: Container(
                            color: Colors.white,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: CustomScrollView(
                                key: ValueKey(
                                  'para_${bloc.arabicFontSize}_'
                                  '${bloc.arabicFontFamily}',
                                ),
                                controller: _scrollViewController,
                                physics: _isPinching
                                    ? const NeverScrollableScrollPhysics()
                                    : const AlwaysScrollableScrollPhysics(),
                                cacheExtent: 5000,
                                slivers: [
                                  SliverPadding(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 20,
                                      bottom: 24,
                                    ),
                                    sliver: SliverList(
                                      delegate: SliverChildListDelegate(
                                        paraArabicScreenWidget,
                                        addAutomaticKeepAlives: false,
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
                  ],
                ),
              ],
            ),
          )),
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
        double diff = position.dy.abs();
        if (diff < minDiff) {
          minDiff = diff;
          // Key format is "surahId_ayatNumber"
          final parts = entry.key.split('_');
          topAyah = int.tryParse(parts[1]);
        }
      }
    }

    SavedPrefernces.updateLastReadOffset(pixels, ayatNumber: topAyah);
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
