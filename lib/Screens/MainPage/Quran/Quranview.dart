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
import '../../../Widgets/reader_bottom_bar.dart';
import 'learn_tajweed_screen.dart';
import 'package:flutter_intro/flutter_intro.dart';
import '../../../Utils/utils.dart';
import '../../../Utils/recitation_reveal.dart';
import 'package:iqra/Helper/favourite.dart';

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

class _QuranViewState extends State<QuranView> with RecitationReaderScreen {
  List<Aya> listAyat = [];
  ArabicNumbers arabicNumber = ArabicNumbers();
  ScrollController? _scrollViewController;
  bool isScrollingDown = false;
  GlobalKey? _targetKey;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false;
  double autoScrollSpeed = 1.0;
  String? _lastRecitedId;
  final Map<int, GlobalKey> _ayahKeys = {};
  late final String _recitationKey;
  bool _startingRecitation = false;
  final GlobalKey _scrollAreaKey = GlobalKey();

  List<Widget> quranViewWidget = [];

  // Tracking for theme/font changes to trigger real-time re-renders
  double? _lastFontSize;
  String? _lastFontFamily;
  Color? _lastThemeColor;
  double _pinchStartFontSize = 30.0;
  double? _pinchStartDistance;
  bool _isPinching = false;
  final Map<int, Offset> _activePointers = {};

  viewMaker() async {
    final bloc = context.read<ThemeProvider>();
    final quranProvider = context.read<QuranDataProvider>();
    final audioProvider = context.read<AudioProvider>();

    _ayahKeys.clear();
    _targetKey = null;
    quranViewWidget.clear();
    List<Widget> textSpanChildren = [];
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

      Widget rtWidget = Container(
        key: key,
        width: double.infinity,
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          textDirection: TextDirection.rtl,
          spacing: (bloc.arabicFontSize * 0.18).clamp(5.0, 9.0),
          runSpacing: (bloc.arabicFontSize * 0.45).clamp(12.0, 22.0),
          children: List<Widget>.from(textSpanChildren),
        ),
      );

      if (isFirstAyat) {
        quranViewWidget.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
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
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0.0),
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
      bool isReciting = audioProvider.isReciting(aya.ayatId);

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

      // Split the verse text into words to wrap them beautifully and maintain RTL order
      List<String> words = text.split(RegExp(r'\s+'));
      for (var word in words) {
        if (word.trim().isEmpty) continue;
        textSpanChildren.add(
          GestureDetector(
            onTap: () {
              SHEET.bottomSheetPreview(
                  context, listAyat, listAyat.indexOf(aya), bloc,
                  showPlayButton: true);
            },
            child: Text(
              word,
              style: TextStyle(
                fontSize: bloc.arabicFontSize,
                fontFamily: bloc.arabicFontFamily,
                color: isTargetAyat ? bloc.selectedTheme : Colors.black,
                fontWeight: isTargetAyat ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
          ),
        );
      }

      final String bookmarkKey = "${aya.surahId}_${aya.ayatNumber}";
      final bool isBookmarked = bookmarkedAyats.contains(bookmarkKey);

      // Add the verse number circle
      textSpanChildren.add(
        GestureDetector(
          onTap: () {
            _toggleAyatBookmark(bookmarkKey);
          },
          child: Container(
            key: _ayahKeys[aya.ayatNumberInt] ??= GlobalKey(),
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
                    : (isTargetAyat
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
                    : (isTargetAyat ? bloc.selectedTheme : Colors.black54),
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
      // Scroll after layout so the verse sits below the fixed header.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ctx = _targetKey?.currentContext;
        if (ctx == null) return;
        revealRecitation(ctx);
      });
    }
  }

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
          content:
              Text('Ayat removed from bookmarks', textAlign: TextAlign.center),
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
    viewMaker(); // Re-render to update the circle UI
  }

  int? _highlightedAyah;

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
    _recitationKey = AudioProvider.queueKeyFor(listAyat);

    // Save as last read
    if (widget.saveLastRead) {
      SavedPrefernces.setLastRead({
        "type": "surah",
        "id": widget.suratNumber,
        "name": widget.surahName,
        "count": widget.ayatCount,
      });
    }

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

    _scrollViewController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset ?? 0.0,
    );
    _scrollViewController!.addListener(() {
      final position = _scrollViewController!.position;
      // Near the top: keep chrome visible; never expand header over text.
      if (position.pixels <= 8) {
        if (isScrollingDown) {
          setState(() => isScrollingDown = false);
        }
        return;
      }

      if (position.userScrollDirection == ScrollDirection.reverse) {
        if (!isScrollingDown) {
          setState(() => isScrollingDown = true);
        }
      } else if (position.userScrollDirection == ScrollDirection.forward) {
        if (isScrollingDown) {
          setState(() => isScrollingDown = false);
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
        viewMaker();
      }
    }

    if (_activePointers.isEmpty) {
      _resumeAutoScrollAfterTouch();
    }
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

  Future<void> _openSettings() async {
    final controller = _scrollViewController;
    final offset =
        controller != null && controller.hasClients ? controller.offset : 0.0;
    await push(context, const SettingScreen());
    if (!mounted) return;
    await viewMaker();
    if (!mounted) return;
    if (controller != null && controller.hasClients) {
      final max = controller.position.maxScrollExtent;
      controller.jumpTo(offset.clamp(0.0, max));
    }
  }

  /// Plays this surah from the first verse on screen, or pauses and resumes
  /// it once it is the recitation playing.
  Future<void> _onRecitationPressed(AudioProvider audio) async {
    if (audio.queueKey == _recitationKey) {
      audio.togglePlayback();
      return;
    }
    final quran = context.read<QuranDataProvider>();
    final surahId = widget.suratNumber ?? 0;
    final topAyah = _firstVisibleAyah();
    // Shows the loading wave until the player takes over, which can take a
    // moment while the connection is checked and the first verse loads.
    setState(() => _startingRecitation = true);
    await audio.startSurahPlayback(
      listAyat,
      quran.recitationTitle(surahId),
      context: context,
      startAyatId: topAyah == null
          ? null
          : listAyat
              .firstWhere((a) => a.ayatNumberInt == topAyah,
                  orElse: () => listAyat.first)
              .ayatId,
      surahTitle: quran.recitationTitle,
    );
    if (mounted) setState(() => _startingRecitation = false);
  }

  /// First verse at least partly in view, or null at the top of the surah so
  /// the recitation starts with Bismillah.
  int? _firstVisibleAyah() {
    final controller = _scrollViewController;
    final area = _scrollAreaKey.currentContext?.findRenderObject();
    if (controller == null ||
        !controller.hasClients ||
        controller.offset < 40 ||
        area is! RenderBox) {
      return null;
    }
    final top = area.localToGlobal(Offset.zero).dy;
    int? first;
    for (final entry in _ayahKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached) continue;
      // Keys mark the end of each verse: a verse is in view once its end is.
      if (box.localToGlobal(Offset.zero).dy < top) continue;
      if (first == null || entry.key < first) first = entry.key;
    }
    return first;
  }

  Widget _buildBottomBar(ThemeProvider bloc, AudioProvider audio) {
    final isOurs = audio.queueKey == _recitationKey;
    final playing = isOurs && audio.isPlaying;
    return ReaderBottomBar(
      color: bloc.selectedTheme,
      centerLabel:
          _startingRecitation ? 'Loading' : (playing ? 'Pause' : 'Listen'),
      centerButton: RecitationPlayButton(
        color: bloc.selectedTheme,
        isPlaying: playing,
        isLoading: _startingRecitation ||
            (isOurs && audio.isBuffering) ||
            (isOurs && audio.isReconnecting),
        onPressed: () => _onRecitationPressed(audio),
      ),
      onPrevious: isOurs ? audio.skipPrevious : null,
      onNext: isOurs && audio.hasNext ? audio.skipNext : null,
      leading: [
        ReaderBarItem(
          icon: _introStep(
            order: 1,
            text: 'Change between Kanz-ul-Iman and Kanz-ul-Irfan translations.',
            icon: Icons.menu_book_rounded,
          ),
          label: bloc.selectedTranslation == "irfan"
              ? "Kanz-ul-Irfan"
              : "Kanz-ul-Iman",
          onTap: () => push(
              context,
              SurahTranslationScreen(
                ayatCount: widget.ayatCount.toString(),
                ayatList: listAyat,
                suratNumber: widget.suratNumber,
                surahName: widget.surahName,
              )),
        ),
        ReaderBarItem(
          icon: _introStep(
            order: 2,
            text:
                'Auto-scroll the page hands-free while reciting or listening.',
            icon: isAutoScrolling
                ? Icons.stop_circle_rounded
                : Icons.fit_screen_rounded,
          ),
          label: isAutoScrolling ? 'Stop' : 'Auto Scroll',
          onTap: _onAutoScrollPressed,
        ),
      ],
      trailing: [
        ReaderBarItem(
          highlight: true,
          icon: Icon(Icons.school_rounded, color: bloc.selectedTheme, size: 22),
          label: 'Learn',
          onTap: _openLearn,
        ),
        ReaderBarItem(
          icon: _introStep(
            order: 3,
            text: 'Customize font size, family, and translation language.',
            icon: Icons.settings_rounded,
          ),
          label: "Setting",
          onTap: _openSettings,
        ),
      ],
    );
  }

  /// The Quran teacher, from the first ayah in view.
  void _openLearn() {
    if (listAyat.isEmpty) return;
    final top = _firstVisibleAyah();
    final index =
        top == null ? 0 : listAyat.indexWhere((a) => a.ayatNumberInt == top);
    push(
        context,
        LearnTajweedScreen(
            ayats: listAyat, initialIndex: index < 0 ? 0 : index));
  }

  Widget _introStep(
      {required int order, required String text, required IconData icon}) {
    return IntroStepBuilder(
      group: 'quran_view',
      order: order,
      getOverlayPosition: (
          {required offset, required screenSize, required size}) {
        return OverlayPosition(
          width: screenSize.width * 0.8,
          crossAxisAlignment: CrossAxisAlignment.center,
          bottom: screenSize.height - offset.dy + 10,
          left: screenSize.width * 0.1,
        );
      },
      overlayBuilder: (params) => buildIntroOverlay(params, text),
      builder: (context, key) =>
          Icon(icon, key: key, color: Colors.white, size: 26),
    );
  }

  void _onAutoScrollPressed() {
    if (isAutoScrolling) {
      _stopAutoScroll();
      return;
    }
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

  @override
  void dispose() {
    // Recitation keeps playing; the global mini player controls it.
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
              : _buildBottomBar(bloc, audioProvider),
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
                      title: widget.surahName ?? '',
                      metadata: metadata,
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
                            key: _scrollAreaKey,
                            color: Colors.white,
                            child: Directionality(
                              textDirection: TextDirection.rtl,
                              child: SingleChildScrollView(
                                controller: _scrollViewController,
                                physics: _isPinching
                                    ? const NeverScrollableScrollPhysics()
                                    : const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                  top: 20,
                                  bottom: 24,
                                ),
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
                  ],
                ),
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
