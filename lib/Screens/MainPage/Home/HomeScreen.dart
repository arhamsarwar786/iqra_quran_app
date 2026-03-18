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
import 'NameofAllah.dart';
import 'NameofMohammad.dart';
import 'package:carousel_slider/carousel_slider.dart';
import "package:timezone/data/latest.dart" as tz;
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:iqra/Provider/prayer_provider.dart';
import 'package:flutter_intro/flutter_intro.dart';

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
  final List<GlobalKey> _introKeys = List.generate(8, (index) => GlobalKey());
  bool _scrolledStep6 = false;
  bool _scrolledStep7 = false;

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

    // Start intro after a short delay so the UI is ready
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        final introContext = Home.scaffoldKey.currentContext;
        if (introContext != null) {
          try {
            Intro.of(introContext).start();
          } catch (e) {
            debugPrint("Failed to start intro: $e");
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

  List<String> imageName = [
    "Rectangle 3.png",
    "Rectangle 4.png",
    "after-prayer-dua.jpg",
    "Rectangle 6.png",
    "Rectangle 7.png",
    "dhikr-After-Salah.jpg",
    "dua-after-prayer.jpg",
    "Good-deeds-to-do-in-Muharram-768x432.jpg",
    "List-of-Adhkar-After-Prayer.jpg",
    "Masnoon-Dua-After-Salah.jpg"
  ];
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
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IntroStepBuilder(
              order: 1,
              text:
                  "Open this menu to find Settings, Help, and more about Iqra Quran.",
              builder: (context, key) => IconButton(
                  key: key,
                  onPressed: () => Home.scaffoldKey.currentState!.openDrawer(),
                  icon: const Icon(Icons.menu)),
            ),
            actions: [
              GestureDetector(
                onTap: () {
                  push(context, const Aboutus());
                },
                child: Icon(
                  Icons.info_outline,
                  size: 30,
                ),
              ),
              const SizedBox(width: 10)
            ],
          ),
          body: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              children: [
                SizedBox(
                  height: 330,
                  child: Stack(
                    children: [
                      CarouselSlider.builder(
                        itemCount: imageName.length,
                        options: CarouselOptions(
                          height: 200,
                          viewportFraction: 1.01,
                          scrollDirection: Axis.horizontal,
                          autoPlay: true,
                        ),
                        itemBuilder: (context, index, pageViewIndex) {
                          return Image(
                            image:
                                AssetImage("assets/images/${imageName[index]}"),
                            width: size.width,
                            fit: BoxFit.fitWidth,
                          );
                        },
                      ),
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bloc.selectedTheme.withOpacity(0.3),
                              bloc.selectedTheme.withOpacity(0.1),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: SearchInQuaran(
                          size: size,
                          bloc: bloc,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                IntroStepBuilder(
                  order: 4,
                  text:
                      "Get accurate Qibla directions and a complete timetable for all 5 prayers.",
                  builder: (context, key) => prayerQiblaList(context, size, bloc, key: key),
                ),
                const SizedBox(height: 10),
                IntroStepBuilder(
                  order: 5,
                  text:
                      "Quickly access the Hijri Calendar, Tasbeeh counter, Kalimas, and Duas.",
                  builder: (context, key) => screensList(context, size, bloc, key: key),
                ),
                const SizedBox(height: 10),
                IntroStepBuilder(
                  order: 6,
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
                      if (!_scrolledStep6 && _introKeys[6].currentContext != null) {
                        _scrolledStep6 = true;
                        Scrollable.ensureVisible(
                          _introKeys[6].currentContext!,
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
                        borderRadius: BorderRadius.circular(16)
                      ),
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
                          ElevatedButton(
                            onPressed: params.onNext,
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
                    );
                  },
                  builder: (context, key) => Container(
                    key: _introKeys[6],
                    child: quranDailyVerse(context, size, bloc, _randomAyat, key: key),
                  ),
                ),
                const SizedBox(height: 10),
                IntroStepBuilder(
                  order: 7,
                  getOverlayPosition: (
                      {required offset, required screenSize, required size}) {
                    return OverlayPosition(
                      width: screenSize.width * 0.9,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      top: 100, // Text stays dynamically at the top while QURAN / ALLAH cards scroll to bottom
                      left: screenSize.width * 0.05,
                    );
                  },
                  overlayBuilder: (params) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!_scrolledStep7 && _introKeys[7].currentContext != null) {
                        _scrolledStep7 = true;
                        Scrollable.ensureVisible(
                          _introKeys[7].currentContext!,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                          alignment: 0.8,
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
                        borderRadius: BorderRadius.circular(16)
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Read and learn the 99 Names of Allah and the Names of Prophet Muhammad (PBUH).",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              height: 1.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: params.onFinish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: bloc.selectedTheme,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text("FINISH",
                                style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                          ),
                        ],
                      ),
                    );
                  },
                  builder: (context, key) => Container(
                    key: _introKeys[7],
                    child: namesAllahProphet(context, size, bloc, key: key),
                  ),
                ),
                const SizedBox(height: 180),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ScreenList //
  Widget screensList(BuildContext context, Size size, ThemeProvider bloc, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
          child: Padding(
            padding: const EdgeInsets.only(
                left: 15.0, right: 15.0, top: 7, bottom: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    push(context, const CalendarScreen());
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 24,
                        width: 17,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/quran${bloc.iconNumber}.png"),
                                fit: BoxFit.fill)),
                      ),
                      Text(
                        "Calender".toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    push(
                      context,
                      Tasbih(
                          // value: nameController.text,
                          ),
                    );
                    // push(context, const TasbeeDetail());
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 25,
                        width: 18,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/Tasbi${int.parse(bloc.iconNumber)}.png"),
                                fit: BoxFit.fill)),
                      ),
                      Text(
                        "TASBEEH",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    push(context, KhalimaScreen());
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 25,
                        width: 24,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                          image: AssetImage(
                              "assets/images/kalma${int.parse(bloc.iconNumber)}.png"),
                          // fit: BoxFit.fill
                        )),
                      ),
                      Text(
                        "Kalima".toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    ],
                  ),
                ),
                InkWell(
                  onTap: () {
                    push(context, const DuaScreen());
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 30,
                        width: 30,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/Dua${int.parse(bloc.iconNumber)}.png"),
                                fit: BoxFit.fill)),
                      ),
                      Text(
                        "DUA",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryColor,
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // PrayerQiblaList //

  Widget prayerQiblaList(BuildContext context, Size size, ThemeProvider bloc, {Key? key}) {
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
      BuildContext context, Size size, ThemeProvider bloc, Aya? randomAyat, {Key? key}) {
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          // color: bloc.selectedTheme.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            // BoxShadow(
                            //   color: bloc.selectedTheme.withOpacity(0.1),
                            //   blurRadius: 10,
                            //   offset: const Offset(0, 4),
                            // ),
                          ],
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
                    ],
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

  // namesAllahProphet //
  Widget namesAllahProphet(
      BuildContext context, Size size, ThemeProvider bloc, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.only(
        left: 8.0,
        right: 8.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              push(context, const NameofAllah());
            },
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(45),
              ),
              child: Container(
                // height: size.height * 0.06,
                width: size.width * 0.43,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "NAME OF ALLAH",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              push(context, const NameofMohammad());
            },
            child: Card(
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(45),
              ),
              child: Container(
                // height: size.height * 0.07,
                width: size.width * 0.43,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(45),
                ),
                child: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: <Widget>[
                        Text(
                          "NAME OF MUHAMMAD",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "(PBUH)",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
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
    );
  }
}

class SearchInQuaran extends StatefulWidget {
  const SearchInQuaran({Key? key, this.size, this.bloc})
      : super(key: key);
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

        return Container(
          width: size.width,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bloc.selectedTheme, bloc.selectedTheme],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: bloc.selectedTheme.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  bottom: -20,
                  child: Icon(
                    Icons.mosque_rounded,
                    size: 180,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // --- Search Bar (Top) ---
                      IntroStepBuilder(
                        order: 2,
                        text:
                            "Instantly search for any Surah, Verse, or topic in the Holy Quran.",
                        builder: (context, key) => InkWell(
                          key: key,
                          onTap: () => push(context, const SearchScreen()),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              children: [
                                const Icon(Icons.search_rounded,
                                    color: Colors.white, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  "Search Quran...",
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                                const Spacer(),
                                Icon(Icons.mic_none_rounded,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      // --- Info Header Row ---
                      IntroStepBuilder(
                        order: 3,
                        text:
                            "Check the current Islamic date and how much time is left for the next prayer.",
                        builder: (context, key) => IntrinsicHeight(
                          key: key,
                          child: Row(
                            children: [
                              // Left: Date
                              Expanded(
                                flex: 11,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded,
                                            size: 14,
                                            color:
                                                Colors.white.withOpacity(0.7)),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('EEEE, d MMM')
                                              .format(_now)
                                              .toUpperCase(),
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 10,
                                              letterSpacing: 1.2,
                                              fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      "${today.hDay} ${today.longMonthName} ${today.hYear} AH",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.5),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        Icon(Icons.location_on_rounded,
                                            size: 12,
                                            color:
                                                Colors.white.withOpacity(0.6)),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data != null
                                                ? data["location"].toUpperCase()
                                                : "DETECTING...",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.6),
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
                              VerticalDivider(
                                  color: Colors.white.withOpacity(0.2),
                                  thickness: 1,
                                  indent: 5,
                                  endIndent: 5),
                              // Right: Prayer
                              Expanded(
                                flex: 9,
                                child: InkWell(
                                  onTap: () =>
                                      push(context, const PrayerTime()),
                                  child: Column(
                                    children: [
                                      Text(
                                        nextPrayerName.toUpperCase(),
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 10,
                                            letterSpacing: 1.2,
                                            fontWeight: FontWeight.w700),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        countdown,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 22,
                                            fontFamily: 'Poppins',
                                            fontWeight: FontWeight.w900),
                                      ),
                                      const SizedBox(height: 2),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          "NAMAZ TIMES",
                                          style: TextStyle(
                                              color: bloc.selectedTheme,
                                              fontSize: 8,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.5),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
