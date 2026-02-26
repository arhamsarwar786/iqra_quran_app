import 'package:iqra/Models/aya_list_model.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Calendar/CalendarScreen.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:iqra/Screens/MainPage/Search/SearchScreen.dart';
import 'package:iqra/Screens/MainPage/Dua/dua_screen.dart';
import 'package:iqra/Screens/MainPage/Home/azan/PrayerTime.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/qibla.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:iqra/Utils/share_verse.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Screens/MainPage/Quran/tabbarview.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:adhan_dart/adhan_dart.dart';
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
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

final _scaffoldKey = GlobalKey<ScaffoldState>();

class _HomeState extends State<Home> {
  Position? position;
  loctionAndZome() async {
    position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  @override
  void initState() {
    tz.initializeTimeZones();
    super.initState();
  }

  Aya? _randomAyat;

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
    return Builder(
      builder: (context) {
        var bloc = context.watch<ThemeProvider>();
        var quranProvider = context.watch<QuranDataProvider>();

        // Load random ayat once when data is available
        if (_randomAyat == null && quranProvider.isLoaded) {
          // Use a post-frame callback or just set it if we are confident it won't cause loops.
          // Since this is inside build, setting a local state variable without setState is tricky if we want it to persist.
          // Better to just store it in a member variable.
          // However, modifying state during build is generally bad.
          // But since this is a one-time init, it acts like a lazy loader.
          _randomAyat = quranProvider.getRandomSmallAyat();
        }
        SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarColor: bloc.selectedSecondary,
          systemNavigationBarIconBrightness: Brightness.dark,
        ));
        return Scaffold(
          backgroundColor: bloc.selectedSecondary,
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: floatinButton(context),
          bottomNavigationBar: BottomBarApp(bloc: bloc),
          extendBodyBehindAppBar: true,
          extendBody:
              true, // Allow body to extend behind bottom bar for immersive feel if needed, or closer to bottom
          // backgroundColor: Colors.red,
          key: _scaffoldKey,
          drawer: const Darwerr(),
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
                onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                icon: const Icon(Icons.menu)),
            actions: [
              GestureDetector(
                onTap: () {
                  push(context, const Aboutus());
                },
                child: Image.asset("assets/images/infoIcon.png"),
              ),
              // IconButton(onPressed: (){

              // }, icon:const Icon(Icons.notifications)),
            ],
          ),
          body: SingleChildScrollView(
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
                      // Overlay with secondary color light on top
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              bloc.selectedTheme.withOpacity(0.3),
                              bloc.selectedTheme.withOpacity(0.1),
                              // Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        child: SearchInQuaran(size: size, bloc: bloc),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),

                prayerQiblaList(context, size, bloc),
                const SizedBox(height: 10),
                screensList(context, size, bloc),
                const SizedBox(height: 10),
                quranDailyVerse(context, size, bloc),
                const SizedBox(height: 10),
                namesAllahProphet(context, size, bloc),
                const SizedBox(height: 80), // Added spacing for bottom bar
              ],
            ),
          ),
        );
      },
    );
  }

  // ScreenList //
  Widget screensList(BuildContext context, Size size, ThemeProvider bloc) {
    return Padding(
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

  Widget prayerQiblaList(BuildContext context, Size size, ThemeProvider bloc) {
    return Padding(
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
  Widget quranDailyVerse(BuildContext context, Size size, ThemeProvider bloc) {
    if (_randomAyat == null) {
      return const SizedBox.shrink();
    }

    // Safety check: if critical details are missing, hidden the card
    if (_randomAyat!.paraId == null ||
        _randomAyat!.surahId == null ||
        _randomAyat!.ayatNumber == null) {
      return const SizedBox.shrink();
    }

    final int surahId = int.tryParse(_randomAyat!.surahId ?? "1") ?? 1;
    final SurahMetadata? surah =
        Provider.of<QuranDataProvider>(context, listen: false)
            .getSurahMetadata(surahId);

    if (surah == null) return const SizedBox.shrink();

    final String surahNameArabic = surah.name;
    final String surahNameEnglish = surah.tname;
    final String verseRef = "$surahId:${_randomAyat!.ayatNumber}";
    final String arabicText = _randomAyat!.arabicText;

    String translationText = "";
    String translatorName = "";

    if (bloc.selectedTranslation == "irfan") {
      translationText = _randomAyat!.tarjumaIrfan ?? "";
      translatorName = "Kanz-ul-Irfan";
    } else {
      translationText = _randomAyat!.tarjumaHind ?? "";
      translatorName = "Kanz-ul-Iman";
    }

    // Fallback if empty
    if (translationText.trim().isEmpty) {
      translationText =
          _randomAyat!.tarjumaIrfan ?? _randomAyat!.tarjumaPak ?? "";
      translatorName = "Kanz-ul-Irfan";
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Card(
        elevation: 5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () {
            final String paraId = _randomAyat!.paraId ?? "1";
            push(
              context,
              ParaArabicScreen(
                parahCount: paraId,
                parahname: "Para $paraId",
                targetAyatNumber: int.tryParse(_randomAyat!.ayatNumber ?? "0"),
                targetSurahNumber: surahId,
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
            child: Column(children: [
              Row(
                children: [
                  Container(
                    height: 26,
                    width: 18,
                    decoration: BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage(
                                "assets/images/quran${bloc.iconNumber}.png"),
                            fit: BoxFit.fill)),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Text(
                    "QURAN",
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => AppShare.image(
                      context: context,
                      bloc: bloc,
                      title: surahNameEnglish,
                      arabicTitle: surahNameArabic,
                      arabicText: arabicText,
                      translationText: translationText,
                      translatorName: translatorName,
                      paraNumber: _randomAyat!.paraId,
                      surahNumber: _randomAyat!.surahId,
                      ayatNumber: _randomAyat!.ayatNumber,
                    ),
                    icon: Icon(Icons.share,
                        color: Theme.of(context).primaryColor),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    surahNameArabic,
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 20,
                        fontFamily: bloc.arabicFontFamily,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Text(
                    verseRef,
                    style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontSize: 17,
                        fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  // const SizedBox(
                  //   width: 20,
                  // ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          arabicText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 30,
                              fontFamily: bloc.arabicFontFamily,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          translationText,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontFamily: bloc.urduFontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ]),
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
      BuildContext context, Size size, ThemeProvider bloc) {
    return Padding(
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
  const SearchInQuaran({Key? key, this.size, this.bloc}) : super(key: key);
  final Size? size;
  final ThemeProvider? bloc;

  @override
  State<SearchInQuaran> createState() => _SearchInQuaranState();
}

class _SearchInQuaranState extends State<SearchInQuaran> {
  Timer? _timer;
  String _prevPrayer = "Loading...";
  String _nextPrayer = "Loading...";
  DateTime? _nextPrayerTime;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadPrayerTimes();
    // Run every second for real-time countdown
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
        // Reload prayer times only every minute to save resources
        if (_now.second == 0) {
          _loadPrayerTimes();
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadPrayerTimes() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (_) {
        final last = await Geolocator.getLastKnownPosition();
        if (last == null) return;
        position = last;
      }

      final coordinates = Coordinates(position.latitude, position.longitude);
      final calcMethod = await SavedPrefernces.getCalculationMethod();
      final madhab = await SavedPrefernces.getMadhab();

      CalculationParameters params;
      switch (calcMethod) {
        case 'karachi':
          params = CalculationMethodParameters.karachi();
          break;
        case 'mwl':
          params = CalculationMethodParameters.muslimWorldLeague();
          break;
        case 'isna':
          params = CalculationMethodParameters.northAmerica();
          break;
        case 'egypt':
          params = CalculationMethodParameters.egyptian();
          break;
        case 'makkah':
        case 'umm_al_qura':
          params = CalculationMethodParameters.ummAlQura();
          break;
        case 'dubai':
          params = CalculationMethodParameters.dubai();
          break;
        case 'turkey':
        case 'turkiye':
          params = CalculationMethodParameters.turkiye();
          break;
        case 'tehran':
          params = CalculationMethodParameters.tehran();
          break;
        case 'singapore':
          params = CalculationMethodParameters.singapore();
          break;
        default:
          params = CalculationMethodParameters.karachi();
      }
      params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

      final now = DateTime.now().toUtc();
      final pt = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
        precision: true,
      );

      final prayers = <Map<String, dynamic>>[];
      void add(String name, DateTime? t) {
        if (t == null) return;
        prayers.add({"name": name, "time": t.toLocal()});
      }

      add("Fajr", pt.fajr);
      add("Zuhr", pt.dhuhr);
      add("Asr", pt.asr);
      add("Maghrib", pt.maghrib);
      add("Isha", pt.isha);
      prayers.sort(
          (a, b) => (a["time"] as DateTime).compareTo(b["time"] as DateTime));

      final nowLocal = DateTime.now();
      Map<String, dynamic>? prev;
      Map<String, dynamic>? next;

      for (final p in prayers) {
        final t = p["time"] as DateTime;
        if (t.isBefore(nowLocal)) {
          prev = p;
        } else if (next == null) {
          next = p;
        }
      }

      if (mounted) {
        setState(() {
          _now = nowLocal;
          _prevPrayer = prev?["name"] ?? prayers.last["name"];
          _nextPrayer = next?["name"] ?? prayers.first["name"];
          _nextPrayerTime = next?["time"] ??
              prayers.first["time"].add(const Duration(days: 1));
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bloc = widget.bloc!;
    final size = widget.size!;
    final today = HijriCalendar.fromDate(_now);

    String countdown = "";
    if (_nextPrayerTime != null) {
      final diff = _nextPrayerTime!.difference(_now);
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
      // padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              bloc.selectedTheme,
              bloc.selectedTheme,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // borderRadius: BorderRadius.circular(30),
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
              // Mosque background decoration
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
                    // Search Bar
                    InkWell(
                      onTap: () => push(context, const SearchScreen()),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(15),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.2)),
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
                                color: Colors.white.withOpacity(0.9), size: 18),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    // Content Row
                    IntrinsicHeight(
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
                                        color: Colors.white.withOpacity(0.7)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "TODAY",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.5,
                                        color: Colors.white.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  DateFormat('EEEE, d MMM').format(_now),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  today.toFormat("dd MMMM yyyy"),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Vertical Divider
                          Container(
                            width: 1,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 15, vertical: 5),
                            color: Colors.white.withOpacity(0.2),
                          ),
                          // Right: Prayer
                          Expanded(
                            flex: 13,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 14,
                                        color: Colors.white.withOpacity(0.7)),
                                    const SizedBox(width: 8),
                                    Text(
                                      "UPCOMING: $_nextPrayer",
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.5,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [Colors.white, Color(0xFFE0E0E0)],
                                  ).createShader(bounds),
                                  child: Text(
                                    countdown,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'Roboto',
                                      letterSpacing: -1,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Text(
                                      "Prev: ",
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.white.withOpacity(0.6)),
                                    ),
                                    Text(
                                      _prevPrayer,
                                      style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.9)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
