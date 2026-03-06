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
  bool _showAppbar = true;
  bool isScrollingDown = true;
  bool isAutoScrolling = false;
  bool _isScrollPaused = false; // finger is on screen while auto-scroll active
  double autoScrollSpeed = 1.0;

  List<Widget> paraArabicScreenWidget = [];
  List<Aya> listAyat = [];
  SurahMetadata? firstSurahMetadata;
  SurahMetadata? currentSurahMetadata;
  Map<String, GlobalKey> surahHeaderKeys = {};
  bool _hasInitialScrolled = false;

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
    _targetKey = null; // Clear old target key
    firstSurahMetadata = null;
    currentSurahMetadata = null;

    List<TextSpan> textSpanChildren = [];
    List<int> currentBatchAyats = []; // Track ayats in current block
    String? currentSurahId;

    for (var aya in listAyat) {
      if (currentSurahId != aya.surahId) {
        if (textSpanChildren.isNotEmpty) {
          GlobalKey? keyForThisBlock;
          // BUG FIX: also check targetSurahNumber so we don't key the wrong surah's block
          final bool blockContainsTarget = _highlightedAyah != null &&
              currentBatchAyats.contains(_highlightedAyah) &&
              (widget.targetSurahNumber == null ||
                  (int.tryParse(currentSurahId ?? "0") ?? 0) ==
                      widget.targetSurahNumber);
          if (blockContainsTarget) {
            keyForThisBlock = GlobalKey();
            _targetKey = keyForThisBlock;
          }
          paraArabicScreenWidget.add(RichText(
            key: keyForThisBlock,
            text: TextSpan(
              children: List.from(textSpanChildren),
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
          textSpanChildren.clear();
          currentBatchAyats.clear();
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

      currentBatchAyats.add(aya.ayatNumberInt);
      // Add the ayah text (already contains inline numbers and markers)
      final int ayaSurahIdIn = int.tryParse(aya.surahId ?? "0") ?? 0;
      bool isTargetAyat = _highlightedAyah != null &&
          aya.ayatNumberInt == _highlightedAyah &&
          (widget.targetSurahNumber == null ||
              ayaSurahIdIn == widget.targetSurahNumber);

      if (isTargetAyat && textSpanChildren.isNotEmpty) {
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
        currentBatchAyats.clear();
        currentBatchAyats.add(aya.ayatNumberInt); // re-add for the new block
      }

      textSpanChildren.add(
        TextSpan(
          text: "${(aya.arabicText).trim()} ",
          style: TextStyle(
            color: isTargetAyat ? bloc.selectedTheme : Colors.black,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              SHEET.bottomSheetPreview(
                  context, listAyat, listAyat.indexOf(aya), bloc);
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

      if (isSajda ||
          isManzil ||
          isRuoEnd ||
          isArba ||
          isNisf ||
          isSalsa ||
          isTargetAyat) {
        // Flush current text block
        if (textSpanChildren.isNotEmpty) {
          GlobalKey? keyForThisBlock;
          // BUG FIX: also check targetSurahNumber to avoid keying the wrong block
          final int surahIdInt = int.tryParse(currentSurahId ?? "0") ?? 0;
          final bool blockContainsTarget = _highlightedAyah != null &&
              currentBatchAyats.contains(_highlightedAyah) &&
              (widget.targetSurahNumber == null ||
                  surahIdInt == widget.targetSurahNumber);
          if (blockContainsTarget) {
            keyForThisBlock = GlobalKey();
            _targetKey = keyForThisBlock;
          }
          paraArabicScreenWidget.add(RichText(
            key: keyForThisBlock,
            text: TextSpan(
              children: List.from(textSpanChildren),
              style: TextStyle(
                  fontSize: bloc.arabicFontSize,
                  fontFamily: bloc.arabicFontFamily,
                  color: Colors.black),
            ),
          ));
          textSpanChildren.clear();
          currentBatchAyats.clear();
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
      GlobalKey? keyForThisBlock;
      // BUG FIX: also check targetSurahNumber
      final int surahIdInt = int.tryParse(currentSurahId ?? "0") ?? 0;
      final bool blockContainsTarget = _highlightedAyah != null &&
          currentBatchAyats.contains(_highlightedAyah) &&
          (widget.targetSurahNumber == null ||
              surahIdInt == widget.targetSurahNumber);
      if (blockContainsTarget) {
        keyForThisBlock = GlobalKey();
        _targetKey = keyForThisBlock;
      }

      paraArabicScreenWidget.add(RichText(
        key: keyForThisBlock,
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

    // Trigger scroll if target key is set
    if (widget.initialScrollOffset != null && !_hasInitialScrolled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollViewController!.hasClients) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (_scrollViewController!.hasClients) {
              _scrollViewController!.jumpTo(widget.initialScrollOffset!);
            }
          });
        }
        _hasInitialScrolled = true;
      });
    } else if (_targetKey != null) {
      // SLIVER SCROLL FIX:
      // SliverList renders lazily. If the target is far down, it doesn't exist yet.
      // We must first jump to an ESTIMATED position to trigger the building of the child.
      _scrollRetryCount = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollViewController != null &&
            _scrollViewController!.hasClients) {
          // Find the index of the keyed widget in our children list
          int targetIndex = paraArabicScreenWidget.indexWhere((w) {
            return w is RichText && w.key == _targetKey;
          });

          if (targetIndex != -1) {
            // Jump to a reasonable estimate so the SliverList builds the widget.
            // Avg height of a text block + spacers is ~130.
            double estimatedOffset = targetIndex * 130.0;
            if (estimatedOffset >
                _scrollViewController!.position.maxScrollExtent) {
              estimatedOffset = _scrollViewController!.position.maxScrollExtent;
            }
            _scrollViewController!.jumpTo(estimatedOffset);
          }

          // Now that we are near, start the polling for exact snap
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback(_scrollToTarget);
          }
        }
      });
    }
  }

  int _scrollRetryCount = 0;
  static const int _maxScrollRetries = 60; // give up after ~1 s

  void _scrollToTarget(Duration _) {
    if (!mounted || _targetKey == null) return;
    final ctx = _targetKey!.currentContext;
    if (ctx != null) {
      // Widget is in the render tree — verify it has a valid size
      final renderObject = ctx.findRenderObject() as RenderBox?;
      if (renderObject != null &&
          renderObject.hasSize &&
          renderObject.size.height > 0) {
        Scrollable.ensureVisible(
          ctx,
          duration: Duration.zero,
          alignment: 0.4, // 40% from top (centered-ish, safe from header)
        );
      } else if (_scrollRetryCount < _maxScrollRetries) {
        _scrollRetryCount++;
        WidgetsBinding.instance.addPostFrameCallback(_scrollToTarget);
      }
    } else if (_scrollRetryCount < _maxScrollRetries) {
      _scrollRetryCount++;
      WidgetsBinding.instance.addPostFrameCallback(_scrollToTarget);
    }
  }

  int? _highlightedAyah;
  GlobalKey? _targetKey;

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
    _highlightedAyah = widget.targetAyatNumber;

    // Save as last read only if requested
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

  /// Called by user's finger going DOWN — pause the ongoing animation
  void _pauseAutoScrollForTouch() {
    if (!isAutoScrolling) return;
    // Stop the in-flight animation by jumping to the current position.
    // isAutoScrolling stays true so we know to resume on finger-up.
    _scrollViewController!.jumpTo(_scrollViewController!.position.pixels);
    _isScrollPaused = true;
  }

  /// Called when the user lifts finger — resume from where we paused.
  void _resumeAutoScrollAfterTouch() {
    if (!isAutoScrolling || !_isScrollPaused) return;
    _isScrollPaused = false;
    _startAutoScroll();
  }

  /// Only called by the STOP button — fully cancels auto-scroll.
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
                              setState(() {
                                autoScrollSpeed = val;
                              });
                              // If currently scrolling, we need to restart with new speed
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
                        label: isAutoScrolling ? "Stop" : "Auto Scroll",
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
                      ),
                    ],
                  ),
                ),
          body: Listener(
            // Listener fires for ALL touch events — more reliable than GestureDetector
            // for grabbing the screen while an animation is running.
            onPointerDown: (_) => _pauseAutoScrollForTouch(),
            onPointerUp: (_) => _resumeAutoScrollAfterTouch(),
            onPointerCancel: (_) => _resumeAutoScrollAfterTouch(),
            child: Container(
              color: Colors.white,
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: NotificationListener<ScrollEndNotification>(
                  onNotification: (scrollEnd) {
                    if (scrollEnd.metrics.axis == Axis.vertical) {
                      SavedPrefernces.updateLastReadOffset(
                          scrollEnd.metrics.pixels);
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _scrollViewController,
                    slivers: [
                      SliverAppBar(
                        automaticallyImplyLeading: false,
                        backgroundColor: currentSurahMetadata != null
                            ? bloc.selectedTheme
                            : Colors.white,
                        expandedHeight:
                            currentSurahMetadata != null ? 166.0 : 56.0,
                        toolbarHeight:
                            currentSurahMetadata != null ? 166.0 : 56.0,
                        floating: false,
                        pinned: true,
                        flexibleSpace: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              height: _showAppbar ? 56.0 : 0.0,
                              duration: const Duration(milliseconds: 200),
                              child: AppBar(
                                automaticallyImplyLeading: false,
                                centerTitle: true,
                                elevation: 0,
                                iconTheme: const IconThemeData(
                                  color: Colors.black,
                                ),
                                backgroundColor: Colors.white,
                                title: Text(
                                  widget.parahname ??
                                      'Para ${widget.parahCount}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: bloc.arabicFontFamily,
                                  ),
                                ),
                                leading: IconButton(
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                              ),
                            ),
                            if (currentSurahMetadata != null)
                              Expanded(
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minHeight: 180),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 800),
                                    switchInCurve: Curves.easeOut,
                                    switchOutCurve: Curves.easeIn,
                                    transitionBuilder: (child, animation) {
                                      return FadeTransition(
                                        opacity: animation,
                                        child: child,
                                      );
                                    },
                                    child: SurahHeaderCard(
                                      key:
                                          ValueKey(currentSurahMetadata!.index),
                                      metadata: currentSurahMetadata!,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.only(
                            top: 5, bottom: 20, left: 15, right: 15),
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
