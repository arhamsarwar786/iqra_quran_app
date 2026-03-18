import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import '../Models/aya_list_model.dart';
import '../Models/surah_metadata_model.dart';
import 'share_quran.dart';
import '../Screens/MainPage/Quran/verse_detail_screen.dart';
import '../widgets.dart';
import '../Provider/audio_provider.dart';
import 'package:flutter_intro/flutter_intro.dart';

class SHEET {
  static bottomSheetPreview(BuildContext context, List<Aya> ayats,
      int initialIndex, ThemeProvider bloc,
      {bool showPlayButton = true}) {
    // Filter out Ayat 0 (Bismillah) if it exists in the list for navigation
    // but check if the initialIndex needs adjustment
    List<Aya> filteredAyats = ayats.where((a) => a.ayatNumber != "0").toList();
    int adjIndex = filteredAyats.indexOf(ayats[initialIndex]);
    if (adjIndex == -1) adjIndex = 0;

    return showModalBottomSheet<void>(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: context,
        builder: (BuildContext context) {
          return _BottomSheetContent(
            ayats: filteredAyats,
            initialIndex: adjIndex,
            bloc: bloc,
            showPlayButton: showPlayButton,
          );
        });
  }

  static Widget _actionButton(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      required Color color}) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetContent extends StatefulWidget {
  final List<Aya> ayats;
  final int initialIndex;
  final ThemeProvider bloc;
  final bool showPlayButton;

  const _BottomSheetContent({
    required this.ayats,
    required this.initialIndex,
    required this.bloc,
    this.showPlayButton = true,
  });

  @override
  State<_BottomSheetContent> createState() => _BottomSheetContentState();
}

class _BottomSheetContentState extends State<_BottomSheetContent> {
  late PageController _pageController;
  late int _currentIndex;
  final ScrollController _introScrollController = ScrollController();
  final GlobalKey _sheetKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted && _sheetKey.currentContext != null) {
        if (_introScrollController.hasClients) {
          _introScrollController.animateTo(
            _introScrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          ).then((_) {
            if (mounted) {
              try {
                Intro.of(_sheetKey.currentContext!).start(group: 'bottom_sheet');
              } catch (_) {}
            }
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _introScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.bloc;
    return Intro(
      maskColor: Colors.black.withOpacity(0.8),
      child: Container(
        key: _sheetKey,
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: bloc.selectedSecondary,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30), topRight: Radius.circular(30)),
        ),
      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              itemCount: widget.ayats.length,
              reverse: true, // RTL behavior for Quran
              itemBuilder: (context, index) {
                final aya = widget.ayats[index];
                final quranProvider =
                    Provider.of<QuranDataProvider>(context, listen: false);
                final int surahId = int.tryParse(aya.surahId ?? "1") ?? 1;
                final SurahMetadata? surah =
                    quranProvider.getSurahMetadata(surahId);

                // Use initialIndex exclusively to prevent GlobalKey collisions across PageView items
                bool isInitialPageAndTutorialTarget = index == widget.initialIndex;

                String translationText = "";
                String translatorName = "";

                if (bloc.selectedTranslation == "irfan") {
                  translationText = aya.tarjumaIrfan ?? "";
                  translatorName = "Kanz-ul-Irfan";
                } else {
                  translationText = aya.tarjumaHind ?? "";
                  translatorName = "Kanz-ul-Iman";
                }

                // Safety fallback for empty translations (e.g. Alif Lam Mim)
                if (translationText.trim().isEmpty) {
                  translationText = aya.tarjumaIrfan ?? aya.tarjumaPak ?? "";
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: SingleChildScrollView(
                    controller: isInitialPageAndTutorialTarget ? _introScrollController : null,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        Center(
                          child: Text(
                            surah?.name ?? "",
                            style: TextStyle(
                              fontFamily: bloc.arabicFontFamily,
                              fontSize: 30,
                              color: bloc.selectedTheme,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ── Source pill: Para · Surah · Verse numbers ──────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: bloc.selectedTheme,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: bloc.selectedTheme.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Para: ${aya.paraId}  •  Surah: ${aya.surahId}  •  Verse: ${aya.ayatNumber}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Divider(height: 40),
                        Directionality(
                          textDirection: TextDirection.rtl,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                aya.arabicText,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: bloc.arabicFontSize - 2,
                                  fontFamily: bloc.arabicFontFamily,
                                  color: Colors.black,
                                  height: 1.8,
                                ),
                              ),
                              const SizedBox(height: 30),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                  border: Border.all(
                                      color:
                                          bloc.selectedTheme.withOpacity(0.05)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      translatorName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: bloc.selectedTheme,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      translationText,
                                      style: TextStyle(
                                        fontSize: bloc.urduFontSize - 3,
                                        fontFamily: bloc.urduFontFamily,
                                        color: Colors.black87,
                                        height: 1.6,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            isInitialPageAndTutorialTarget
                                ? IntroStepBuilder(
                                    group: 'bottom_sheet',
                                    order: 1,
                                    overlayBuilder: (params) => Container(
                                      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Share this Ayat as an image to WhatsApp or others.',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: params.onNext,
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                                            child: const Text('Next'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    builder: (context, key) => Container(
                                      key: key,
                                      child: SHEET._actionButton(
                                        context,
                                        icon: Icons.share,
                                        label: "Share",
                                        onTap: () {
                                          QuranShare.image(
                                            context: context,
                                            bloc: bloc,
                                            title: surah?.tname ?? "",
                                            arabicTitle: surah?.name ?? "",
                                            arabicText: aya.arabicText,
                                            translationText: translationText,
                                            translatorName: translatorName,
                                            surahNumber: aya.surahId,
                                            ayatNumber: aya.ayatNumber,
                                            paraNumber: aya.paraId,
                                          );
                                        },
                                        color: bloc.selectedTheme,
                                      ),
                                    ),
                                  )
                                : SHEET._actionButton(
                                    context,
                                    icon: Icons.share,
                                    label: "Share",
                                    onTap: () {
                                      QuranShare.image(
                                        context: context,
                                        bloc: bloc,
                                        title: surah?.tname ?? "",
                                        arabicTitle: surah?.name ?? "",
                                        arabicText: aya.arabicText,
                                        translationText: translationText,
                                        translatorName: translatorName,
                                        surahNumber: aya.surahId,
                                        ayatNumber: aya.ayatNumber,
                                        paraNumber: aya.paraId,
                                      );
                                    },
                                    color: bloc.selectedTheme,
                                  ),
                            const SizedBox(width: 15),
                            isInitialPageAndTutorialTarget
                                ? IntroStepBuilder(
                                    group: 'bottom_sheet',
                                    order: 2,
                                    overlayBuilder: (params) => Container(
                                      margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.black87,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Read detailed Urdu Tafseer for this Verse.',
                                              style: TextStyle(color: Colors.white, fontSize: 12),
                                              textAlign: TextAlign.center),
                                          const SizedBox(height: 8),
                                          ElevatedButton(
                                            onPressed: widget.showPlayButton ? params.onNext : params.onFinish,
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                                            child: Text(widget.showPlayButton ? 'Next' : 'Finish'),
                                          ),
                                        ],
                                      ),
                                    ),
                                    builder: (context, key) => Container(
                                      key: key,
                                      child: SHEET._actionButton(
                                        context,
                                        icon: Icons.menu_book_rounded,
                                        label: "Tafseer",
                                        onTap: () {
                                          push(
                                            context,
                                            VerseDetailScreen(
                                              aya: aya,
                                              surahMetadata: surah,
                                            ),
                                          );
                                        },
                                        color: bloc.selectedTheme,
                                      ),
                                    ),
                                  )
                                : SHEET._actionButton(
                                    context,
                                    icon: Icons.menu_book_rounded,
                                    label: "Tafseer",
                                    onTap: () {
                                      push(
                                        context,
                                        VerseDetailScreen(
                                          aya: aya,
                                          surahMetadata: surah,
                                        ),
                                      );
                                    },
                                    color: bloc.selectedTheme,
                                  ),
                            if (widget.showPlayButton)
                              isInitialPageAndTutorialTarget
                                  ? IntroStepBuilder(
                                      group: 'bottom_sheet',
                                      order: 3,
                                      overlayBuilder: (params) => Container(
                                        margin: const EdgeInsets.only(top: 10, left: 10, right: 10),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.black87,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Listen to the audio recitation of this Ayat.',
                                                style: TextStyle(color: Colors.white, fontSize: 12),
                                                textAlign: TextAlign.center),
                                            const SizedBox(height: 8),
                                            ElevatedButton(
                                              onPressed: params.onFinish,
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black),
                                              child: const Text('Finish'),
                                            ),
                                          ],
                                        ),
                                      ),
                                      builder: (context, key) => Container(
                                        key: key,
                                        child: SHEET._actionButton(
                                          context,
                                          icon: Icons.play_arrow_rounded,
                                          label: "Play",
                                          onTap: () {
                                            final audio =
                                                context.read<AudioProvider>();
                                            Navigator.pop(context); // Close sheet
                                            audio.stopPlayback().then((_) {
                                              audio.startSurahPlayback(
                                                context,
                                                widget.ayats,
                                                surah?.name ?? "Surah",
                                                startAyatId: aya.ayatId,
                                              );
                                            });
                                          },
                                          color: bloc.selectedTheme,
                                        ),
                                      ),
                                    )
                                  : SHEET._actionButton(
                                      context,
                                      icon: Icons.play_arrow_rounded,
                                      label: "Play",
                                      onTap: () {
                                        final audio =
                                            context.read<AudioProvider>();
                                        Navigator.pop(context); // Close sheet
                                        audio.stopPlayback().then((_) {
                                          audio.startSurahPlayback(
                                            context,
                                            widget.ayats,
                                            surah?.name ?? "Surah",
                                            startAyatId: aya.ayatId,
                                          );
                                        });
                                      },
                                      color: bloc.selectedTheme,
                                    ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _navButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: _currentIndex < widget.ayats.length - 1
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                  color: bloc.selectedTheme,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "AYAT",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[400],
                        letterSpacing: 2,
                      ),
                    ),
                    Text(
                      "${_currentIndex + 1} / ${widget.ayats.length}",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: bloc.selectedTheme,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                _navButton(
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: _currentIndex > 0
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      : null,
                  color: bloc.selectedTheme,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  static Widget _navButton(
      {required IconData icon,
      required VoidCallback? onPressed,
      required Color color}) {
    return Material(
      color: onPressed == null ? Colors.grey[100] : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(15),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon,
            color: onPressed == null ? Colors.grey[400] : color, size: 18),
        padding: const EdgeInsets.all(12),
      ),
    );
  }
}
