import 'dart:developer';

import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Calendar/CalendarScreen.dart';
import 'package:iqra/Screens/MainPage/Quran/Quranview.dart';
import 'package:iqra/Screens/MainPage/Quran/verse_detail_screen.dart';
import 'package:iqra/Screens/MainPage/Search/SearchScreen.dart';
import 'package:iqra/Screens/MainPage/Dua/dua_screen.dart';
import 'package:iqra/Screens/MainPage/Home/azan/PrayerTime.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/qibla.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Utils/share_verse.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../widgets.dart';
import '../Drawer/Drawerr Screen.dart';
import '../Drawer/About Us.dart';
import '../Khalima/kalma_screen.dart';
import '../main_screen.dart';
import '../Quran/tabbarview.dart';
import 'NameofAllah.dart';
import 'NameofMohammad.dart';
// carousel_slider removed
import "package:timezone/data/latest.dart" as tz;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:iqra/Provider/prayer_provider.dart';
import 'package:flutter_intro/flutter_intro.dart';
import 'package:iqra/Utils/utils.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/features/hajj_live/hajj_live_module.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);
  // Define static scaffoldKey so MainScreen can access it
  static final GlobalKey<ScaffoldState> scaffoldKey =
      GlobalKey<ScaffoldState>();

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _introKeys = List.generate(9, (index) => GlobalKey());
  bool _scrolledStep7 = false;
  bool _scrolledStep8 = false;
  bool _isScrolled = false;

  @override
  void initState() {
    tz.initializeTimeZones();
    super.initState();

    // Pre-load prayer data for instant access
    Future.microtask(() {
      if (mounted) {
        context.read<PrayerProvider>().fetchPrayerData();
      }
    });

    _scrollController.addListener(() {
      if (_scrollController.offset > 40 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 40 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });

    // Start intro after a delay to ensure the UI and all steps are ready
    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        bool showTuts = await SavedPrefernces.getShowTutorials();
        bool hasSeen = await SavedPrefernces.hasSeenTutorial('home');
        if (showTuts && !hasSeen) {
          final introContext = Home.scaffoldKey.currentContext;
          if (introContext != null) {
            try {
              // Force discovery of all steps in the ScrollView
              Intro.of(introContext).start();
              await SavedPrefernces.markTutorialSeen('home');
            } catch (e) {
              debugPrint("Failed to start intro: $e");
            }
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var bloc = context.watch<ThemeProvider>();
    var quranProvider = context.watch<QuranDataProvider>();

    Aya? _randomAyat = quranProvider.currentRandomAyat;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: bloc.selectedTheme,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Intro(
        maskColor: Colors.black.withOpacity(0.8),
        child: Scaffold(
          backgroundColor: bloc.selectedSecondary,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: floatinButton(context),
          bottomNavigationBar: BottomBarApp(bloc: bloc),
          extendBodyBehindAppBar: true,
          key: Home.scaffoldKey,
          drawer: const Darwerr(),
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: _isScrolled ? bloc.selectedTheme.withOpacity(0.95) : Colors.transparent,
            elevation: _isScrolled ? 2 : 0,
            leading: IntroStepBuilder(
              order: 1,
              overlayBuilder: (params) => buildIntroOverlay(params,
                  "Open this menu to find Settings, Help, and more about Iqra Quran."),
              builder: (context, key) => IconButton(
                  key: key,
                  onPressed: () => Home.scaffoldKey.currentState!.openDrawer(),
                  icon: const Icon(Icons.menu)),
            ),
            actions: [
              IntroStepBuilder(
                order: 3,
                overlayBuilder: (params) => buildIntroOverlay(params,
                    "Instantly search for any Surah, Verse, or topic in the Holy Quran."),
                builder: (context, key) => InkWell(
                  key: key,
                  onTap: () => push(context, const SearchScreen()),
                  child: Container(
                    height: 40,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    // padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Icon(Icons.search_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
              ),
              SizedBox(
                width: 10,
              ),
              IntroStepBuilder(
                order: 2,
                overlayBuilder: (params) => buildIntroOverlay(params,
                    "Learn more about Iqra Quran, its creators, and get in touch."),
                builder: (context, key) => GestureDetector(
                  key: key,
                  onTap: () {
                    push(context, const Aboutus());
                  },
                  child: const Icon(
                    Icons.info_outline,
                    size: 30,
                  ),
                ),
              ),
              const SizedBox(width: 10)
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SearchInQuaran(size: size, bloc: bloc),
                const SizedBox(height: 5),
                // Removed redundant prayerQiblaList since items are now in the grid
                const SizedBox(height: 10),
                IntroStepBuilder(
                  order: 6,
                  overlayBuilder: (params) => buildIntroOverlay(params,
                      "Quickly access the Hijri Calendar, Tasbeeh counter, Kalimas, and Duas."),
                  builder: (context, key) =>
                      screensList(context, size, bloc, key: key),
                ),
                const SizedBox(height: 10),
                const HajjLiveCard(),
                const SizedBox(height: 10),
                IntroStepBuilder(
                  order: 7,
                  getOverlayPosition: (
                      {required offset, required screenSize, required size}) {
                    return OverlayPosition(
                      width: screenSize.width * 0.9,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      top: 80, // Place text safely near the top of the screen
                      left: screenSize.width * 0.05,
                    );
                  },
                  overlayBuilder: (params) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scrolledStep7 &&
                          _introKeys[7].currentContext != null) {
                        _scrolledStep7 = true;
                        Scrollable.ensureVisible(
                          _introKeys[7].currentContext!,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          alignment: 0.3,
                        ).then((_) {
                          final introC = Home.scaffoldKey.currentContext;
                          if (introC != null && introC.mounted) {
                            try {
                              Intro.of(introC).refresh();
                            } catch (_) {}
                          }
                        });
                      }
                    });
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Get a beautiful new verse from the Quran every 3 Minutes with translation.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: params.onFinish,
                                child: const Text("SKIP",
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () {
                                  // Explicitly finish the first guide group and start the next
                                  params.onFinish();

                                  final introC =
                                      Home.scaffoldKey.currentContext;
                                  if (introC != null) {
                                    // Provide a small delay to let the previous mask fade out
                                    Future.delayed(
                                        const Duration(milliseconds: 400), () {
                                      if (introC.mounted) {
                                        Intro.of(introC)
                                            .start(group: 'step8', reset: true);
                                      }
                                    });
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: bloc.selectedTheme,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 12),
                                ),
                                child: const Text("NEXT",
                                    style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  builder: (context, key) => Container(
                    key: _introKeys[7],
                    child: quranDailyVerse(context, size, bloc, _randomAyat,
                        key: key),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ScreenList — 4×2 grid (8 features) //
  Widget screensList(BuildContext context, Size size, ThemeProvider bloc,
      {Key? key}) {
    final Color iconBg = bloc.selectedTheme.withOpacity(0.12);
    final Color iconColor = bloc.selectedTheme;

    Widget gridItem({
      required String label,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return Expanded(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: bloc.selectedTheme.withOpacity(0.85),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Column(
        children: [
          // Row 1: Qibla, Quran, Duas, Tasbeeh
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              gridItem(
                label: "Qibla",
                icon: Icons.explore_rounded,
                onTap: () => push(context, const DirectionTOQiblah()),
              ),
              gridItem(
                label: "Quran",
                icon: Icons.auto_stories_rounded,
                onTap: () => push(context, const TabBarDemo()),
              ),
              gridItem(
                label: "Duas",
                icon: Icons.volunteer_activism_rounded,
                onTap: () => push(context, const DuaScreen()),
              ),
              gridItem(
                label: "Tasbeeh",
                icon: Icons.blur_circular_rounded,
                onTap: () => push(context, Tasbih()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Row 2: Calendar, Kalima, Prayer Time, Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              gridItem(
                label: "Calendar",
                icon: Icons.calendar_month_rounded,
                onTap: () => push(context, const CalendarScreen()),
              ),
              gridItem(
                label: "Kalima",
                icon: Icons.brightness_5_rounded,
                onTap: () => push(context, KhalimaScreen()),
              ),
              gridItem(
                label: "Prayers",
                icon: Icons.access_time_filled_rounded,
                onTap: () => push(context, const PrayerTime()),
              ),
              gridItem(
                label: "99 Names",
                icon: Icons.mosque_rounded,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      title: Text(
                        "Select Names",
                        style: TextStyle(
                          color: bloc.selectedTheme,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading:
                                Icon(Icons.mosque, color: bloc.selectedTheme),
                            title: const Text("Names of Allah",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () {
                              Navigator.pop(ctx);
                              push(context, const NameofAllah());
                            },
                          ),
                          const Divider(),
                          ListTile(
                            leading:
                                Icon(Icons.star, color: bloc.selectedTheme),
                            title: const Text("Names of Muhammad ﷺ",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            onTap: () {
                              Navigator.pop(ctx);
                              push(context, const NameofMohammad());
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // PrayerQiblaList //

  Widget prayerQiblaList(BuildContext context, Size size, ThemeProvider bloc,
      {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Card(
            elevation: 10,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            child: InkWell(
              onTap: () {
                push(context, const DirectionTOQiblah());
              },
              child: Container(
                height: size.height * 0.06,
                width: size.width * 0.42,
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        // padding: EdgeInsets.only(left: 10),
                        // height: size.height * 0.04,
                        // width: size.width * 0.06,
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage("assets/images/compass.png"),
                                fit: BoxFit.fill)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Text(
                        "QIBLA DIRECTION",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              push(context, const PrayerTime());
            },
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              child: Container(
                height: size.height * 0.06,
                width: size.width * 0.42,
                decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    // color: Colors.white,
                    border: Border.all(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(30)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                            image: DecorationImage(
                                image:
                                    AssetImage("assets/images/prayerTime.png"),
                                fit: BoxFit.cover)),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      const Center(
                        child: Text(
                          "PRAYER TIME",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // quranDailyVerse //
  Widget quranDailyVerse(
      BuildContext context, Size size, ThemeProvider bloc, Aya? randomAyat,
      {Key? key}) {
    if (randomAyat == null) {
      return CircularProgressIndicator(
        key: key,
        backgroundColor: bloc.selectedTheme,
      );
    }

    // Safety check: if critical details are missing, hidden the card
    if (randomAyat.paraId == null ||
        randomAyat.surahId == null ||
        randomAyat.ayatNumber == null) {
      return const SizedBox.shrink();
    }

    final int surahId = int.tryParse(randomAyat.surahId ?? "1") ?? 1;
    final SurahMetadata? surah =
        Provider.of<QuranDataProvider>(context, listen: false)
            .getSurahMetadata(surahId);

    if (surah == null) return const SizedBox.shrink();

    final String surahNameArabic = surah.name;
    final String surahNameEnglish = surah.tname;
    final String verseRef = "$surahId:${randomAyat.ayatNumber}";
    final String arabicText = randomAyat.arabicText;

    String translationText = "";
    String translatorName = "";

    if (bloc.selectedTranslation == "irfan") {
      translationText = randomAyat.tarjumaIrfan ?? "";
      translatorName = "Kanz-ul-Irfan";
    } else {
      translationText = randomAyat.tarjumaHind ?? "";
      translatorName = "Kanz-ul-Iman";
    }

    // Fallback if empty
    if (translationText.trim().isEmpty) {
      translationText = randomAyat.tarjumaIrfan ?? randomAyat.tarjumaPak ?? "";
      translatorName = "Kanz-ul-Irfan";
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            push(
              context,
              QuranView(
                suratNumber: surahId,
                surahName: surahNameEnglish,
                ayatCount: surah.ayas,
                targetAyatNumber: randomAyat.ayatNumberInt,
                saveLastRead: false,
              ),
            );
          },
          child: Container(
            padding:
                const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
            width: size.width,
            decoration: BoxDecoration(
              // color: bloc.selectedSecondary, // Moved to Card for InkWell
              borderRadius: BorderRadius.circular(30),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 800),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.05),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(verseRef),
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                                color: bloc.selectedTheme,
                                borderRadius: BorderRadius.circular(100),
                                image: DecorationImage(
                                    image: AssetImage(
                                        "assets/images/iqra-white.png"),
                                    fit: BoxFit.fill)),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "QURAN",
                            style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () => AppShare.image(
                                context: context,
                                bloc: bloc,
                                title: surahNameEnglish,
                                arabicTitle: surahNameArabic,
                                arabicText: arabicText,
                                translationText: translationText,
                                translatorName: translatorName,
                                paraNumber: randomAyat.paraId,
                                surahNumber: randomAyat.surahId,
                                ayatNumber: randomAyat.ayatNumber,
                              ),
                              icon: Icon(Icons.share,
                                  color: Theme.of(context).primaryColor),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: "Share",
                            ),
                            const SizedBox(width: 15),
                            Flexible(
                              child: Text(
                                surahNameArabic,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontSize: 18,
                                    fontFamily: bloc.arabicFontFamily,
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    arabicText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 28, // slight reduction to fit better
                        fontFamily: bloc.arabicFontFamily,
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    translationText,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontFamily: bloc.urduFontFamily,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // ── Source pill: Para · Surah · Verse numbers ──────
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: const [],
                      ),
                      child: Text(
                        "Para: ${randomAyat.paraId}  •  Surah: ${randomAyat.surahId}  •  Verse: ${randomAyat.ayatNumber}",
                        style: TextStyle(
                          color: bloc.selectedTheme,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () {
                          push(
                            context,
                            VerseDetailScreen(
                              aya: randomAyat,
                              surahMetadata: surah,
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          height: 40,
                          // width: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(45),
                            border: Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              "Tafseer",
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // // hadeesDailyVerse //
  // Widget hadeesDailyVerse(BuildContext context, Size size,ThemeProvider bloc) {
  //   return Card(
  //     elevation: 5,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
  //     child: Container(
  //       // height: size.height * 0.27,
  //       width: size.width,
  //       decoration: BoxDecoration(
  //         color: Colors.white,
  //         borderRadius: BorderRadius.circular(30),
  //       ),
  //       child: Column(children: [
  //         Container(
  //           height: 50,
  //           decoration: BoxDecoration(
  //               color: Theme.of(context).primaryColor,
  //               borderRadius: const BorderRadius.only(
  //                 topLeft: Radius.circular(30),
  //                 topRight: Radius.circular(30),
  //               )),
  //           child: Padding(
  //             padding: const EdgeInsets.only(left: 15.0, top: 2, bottom: 2),
  //             child: Row(
  //               children: [
  //                 Container(
  //                   height: 35,
  //                   width: 35,
  //                   decoration: const BoxDecoration(
  //                       image: DecorationImage(
  //                           image: AssetImage("assets/images/Hadees1.png"),
  //                           fit: BoxFit.fill)),
  //                 ),
  //                 const SizedBox(
  //                   width: 5,
  //                 ),
  //                 const Text(
  //                   "HADEES",
  //                   style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: 15,
  //                       fontWeight: FontWeight.w700),
  //                 )
  //               ],
  //             ),
  //           ),
  //         ),
  //         Padding(
  //           padding: const EdgeInsets.symmetric(vertical: 50),
  //           child: Center(
  //             child: Text(
  //               "COMING SOON",
  //               style: TextStyle(
  //                   color: Theme.of(context).primaryColor,
  //                   fontSize: 15,
  //                   fontWeight: FontWeight.w600,
  //                   height: 1.3,
  //                   decorationThickness: 2.0),
  //             ),
  //           ),
  //         ),
  //       ]),
  //     ),
  //   );
  // }
}

class SearchInQuaran extends StatefulWidget {
  const SearchInQuaran({Key? key, this.size, this.bloc}) : super(key: key);
  final Size? size;
  final ThemeProvider? bloc;

  @override
  State<SearchInQuaran> createState() => _SearchInQuaranState();
}

class _SearchInQuaranState extends State<SearchInQuaran> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Periodic update for the countdown string
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.bloc!;
    final size = widget.size!;
    final today =
        HijriCalendar.fromDate(_now.add(Duration(days: bloc.hijriOffset)));

    return Consumer<PrayerProvider>(
      builder: (context, provider, child) {
        final data = provider.prayerData;
        String nextPrayerName = "Loading...";
        String countdown = "--:--:--";

        if (data != null) {
          final List<Map<String, dynamic>> fardList = data["fardList"];
          final DateTime nextFajr = data["nextFajr"];

          Map<String, dynamic>? next;
          for (final p in fardList) {
            if ((p["dateTime"] as DateTime).isAfter(_now)) {
              next = p;
              break;
            }
          }

          DateTime nextTime = next != null ? next["dateTime"] : nextFajr;
          nextPrayerName = next != null ? next["name"] : "Fajr";

          final diff = nextTime.difference(_now);
          if (!diff.isNegative) {
            int h = diff.inHours;
            int m = diff.inMinutes.remainder(60);
            int s = diff.inSeconds.remainder(60);
            countdown =
                "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}";
          }
        }

        final topPad = MediaQuery.of(context).padding.top;

        return ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
          child: Stack(
            children: [
              // ── Mosque background image ──────────────────────────────
              SizedBox(
                width: size.width,
                height: topPad + 250,
                child: Image.asset(
                  "assets/images/Rectangle 3.png",
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                ),
              ),
              // ── Theme gradient overlay ───────────────────────────────
              Container(
                width: size.width,
                height: topPad + 250,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bloc.selectedTheme.withOpacity(0.55),
                      bloc.selectedTheme.withOpacity(0.92),
                    ],
                  ),
                ),
              ),
              // ── Mosque icon watermark ────────────────────────────────
              Positioned(
                right: -25,
                bottom: -10,
                child: Icon(
                  Icons.mosque_rounded,
                  size: 160,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              // ── Foreground content ───────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(18, topPad + 10, 18, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- Search Bar ---
                    // const SizedBox(height: 20),
                    // --- Date + Prayer Row ---
                    IntroStepBuilder(
                      order: 4,
                      overlayBuilder: (params) => buildIntroOverlay(params,
                          "Check the current Islamic date and how much time is left for the next prayer."),
                      builder: (context, key) => IntrinsicHeight(
                        key: key,
                        child: Row(
                          children: [
                            // Left: Hijri date + location
                            Expanded(
                              flex: 11,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 13,
                                          color:
                                              Colors.white.withOpacity(0.75)),
                                      const SizedBox(width: 6),
                                      Text(
                                        DateFormat('EEEE, d MMM')
                                            .format(_now)
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.75),
                                            fontSize: 10,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${today.hDay} ${today.longMonthName} ${today.hYear} AH",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.4),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on_rounded,
                                          size: 11,
                                          color:
                                              Colors.white.withOpacity(0.65)),
                                      const SizedBox(width: 3),
                                      Expanded(
                                        child: Text(
                                          data != null
                                              ? data["location"].toUpperCase()
                                              : "DETECTING...",
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.65),
                                              fontSize: 9,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // Divider
                            VerticalDivider(
                                color: Colors.white.withOpacity(0.25),
                                thickness: 1,
                                indent: 4,
                                endIndent: 4),
                            // Right: Next prayer countdown
                            Expanded(
                              flex: 9,
                              child: InkWell(
                                onTap: () => push(context, const PrayerTime()),
                                borderRadius: BorderRadius.circular(12),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      nextPrayerName.toUpperCase(),
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.75),
                                          fontSize: 10,
                                          letterSpacing: 1.5,
                                          fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      countdown,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        "NAMAZ TIMES",
                                        style: TextStyle(
                                            color: bloc.selectedTheme,
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // --- Horizontal Prayer Row ---
                    if (data != null && data["fardList"] != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: (data["fardList"] as List).map((prayer) {
                            final String name = prayer["name"].toString();
                            final bool isNext = name.toUpperCase() ==
                                nextPrayerName.toUpperCase();
                            String formattedTime = prayer["time"].toString();
                            try {
                              final dt =
                                  DateFormat("h:mm a").parse(formattedTime);
                              formattedTime = DateFormat("HH:mm").format(dt);
                            } catch (_) {}

                            IconData icon;
                            switch (name.toLowerCase()) {
                              case 'fajr':
                                icon = Icons.wb_twilight_rounded;
                                break;
                              case 'zuhr':
                              case 'dhuhr':
                                icon = Icons.wb_sunny_rounded;
                                break;
                              case 'asr':
                                icon = Icons.wb_cloudy_rounded;
                                break;
                              case 'maghrib':
                                icon = Icons.nights_stay_rounded;
                                break;
                              case 'isha':
                                icon = Icons.mode_night_rounded;
                                break;
                              default:
                                icon = Icons.access_time_rounded;
                            }

                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10),
                                decoration: isNext
                                    ? BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          )
                                        ],
                                      )
                                    : null,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      icon,
                                      color: isNext
                                          ? bloc.selectedTheme
                                          : Colors.white,
                                      size: 22,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      style: TextStyle(
                                        color: isNext
                                            ? bloc.selectedTheme
                                            : Colors.white,
                                        fontSize: 11,
                                        fontWeight: isNext
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(
                                        color: isNext
                                            ? bloc.selectedTheme
                                                .withOpacity(0.8)
                                            : Colors.white.withOpacity(0.8),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
