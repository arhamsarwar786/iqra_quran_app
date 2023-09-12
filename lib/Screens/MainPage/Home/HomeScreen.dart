import 'package:flutter/cupertino.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Dua/dua_screen.dart';
import 'package:iqra/Screens/MainPage/Home/azan/PrayerTime.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/qibla.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee_detail.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import '../../../Provider/main_provider.dart';
import '../../../Utils/constants.dart';
import '../../../widgets.dart';
import '../Drawer/Drawerr Screen.dart';
import '../Khalima/kalma_screen.dart';
import '../main_screen.dart';
import 'NameofAllah.dart';
import 'NameofMohammad.dart';
import 'package:carousel_slider/carousel_slider.dart';
import "package:timezone/data/latest.dart" as tz;

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

  HijriCalendar _today = HijriCalendar.fromDate(DateTime.now());
  List<String> imageName = [
    "Rectangle 3.png",
    "Rectangle 4.png",
    "Rectangle 5.png",
    "Rectangle 6.png",
    "Rectangle 7.png",
  ];
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Builder(builder: (context) {
      var bloc = context.watch<ThemeProvider>();
      return SafeArea(
        child: Scaffold(
          // backgroundColor: bloc.selectedSecondary,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
            floatingActionButton: floatinButton(context),
            bottomNavigationBar: BottomBarApp(bloc:bloc),
            extendBodyBehindAppBar: true,
            // backgroundColor: Colors.red,
            // key: _scaffoldKey,
            drawer: Darwerr(),
            resizeToAvoidBottomInset: false,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                  onPressed: () => _scaffoldKey.currentState!.openDrawer(),
                  icon: const Icon(Icons.menu)),
              actions: [
                GestureDetector(
                  onTap: () {},
                  child: Image.asset("assets/images/infoIcon.png"),
                ),
                // IconButton(onPressed: (){

                // }, icon:const Icon(Icons.notifications)),
              ],
            ),
            body: Column(
              children: [
                SizedBox(
                  // color: Colors.yellow,
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
                          // enlargeStrategy: CenterPageEnlargeStrategy.height,
                        ),
                        itemBuilder: (context, index, pageViewIndex) {
                          return Image(
                            image:
                                AssetImage("assets/images/${imageName[index]}"),
                            width: size.width,
                            fit: BoxFit.fitWidth,
                            // height: 30,
                          );
                        },
                      ),
                      Positioned(
                          bottom: 0,
                          child: SearchInQuaran(
                              today: _today, size: size, bloc: bloc)),
                    ],
                  ),
                ),
                // Container(height: 50,color: Colors.transparent,),
                Expanded(
                  child: SingleChildScrollView(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        prayerQiblaList(context, size, bloc),
                        const SizedBox(
                          height: 10,
                        ),
                        screensList(context, size, bloc),
                        // prayerQiblaList
                        const SizedBox(
                          height: 10,
                        ),
                        // hadeesDailyVerse
                        quranDailyVerse(context, size, bloc),
                        const SizedBox(
                          height: 10,
                        ),
                        namesAllahProphet(context, size, bloc),
                        const SizedBox(
                          height: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      );
    });
  }

  // ScreenList //
  Widget screensList(BuildContext context, Size size, ThemeProvider bloc) {
    MyProvider provider = Provider.of<MyProvider>(context, listen: false);
    return Padding(
padding: const EdgeInsets.only(left: 8.0,
                      right: 8.0,),      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(30)),
          child: Padding(
            padding:
                const EdgeInsets.only(left: 15.0, right: 15.0, top: 7, bottom: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                InkWell(
                  onTap: () {
                    push(context, const PrayerTime());
                    // push(context, TabBarDemo());
                  },
                  child: Column(
                    children: [
                      Container(
                        height: 24,
                        width: 17,
                        decoration: BoxDecoration(
                            image: DecorationImage(
                                image: AssetImage(
                                    "assets/images/namaz${int.parse(bloc.iconNumber)}.png"),
                                fit: BoxFit.fill)),
                      ),
                      Text(
                        " Namaz",
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
                    // provider.screenIndex = 2;
                    // pushUntil(context, MainScreen());
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
                        "KHALIMA",
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
                    push(context, TasbeeDetail());
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
      padding: const EdgeInsets.only(left: 8.0,
                      right: 8.0,),
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
                push(context, DirectionTOQiblah());
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
              push(context, PrayerTime());
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
                                image: AssetImage("assets/images/prayerTime.png"),
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
    return Card(
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding:
            const EdgeInsets.only(top: 20, left: 10, right: 10, bottom: 20),
        width: size.width,
        decoration: BoxDecoration(
          color: bloc.selectedSecondary,
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
              Spacer(),
              Text(
                "البقرة",
                style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 20,
                    fontFamily: bloc.arabicFontFamily,
                    fontWeight: FontWeight.w700),
              ),
              SizedBox(width: 10,),
              Text(
                "1-23",
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
                      " ذٰلِكَ الۡڪِتٰبُ لَا رَيۡبَ ۛۚ  ۖ فِيۡهِ ۛۚ هُدًى لِّلۡمُتَّقِيۡنَۙ‏",
                      textAlign: TextAlign.right,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 30,
                          fontFamily: bloc.arabicFontFamily,
                          fontWeight: FontWeight.w500),
                    ),
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      "یہ اللہ کی کتاب ہے، اس میں کوئی شک نہیں ہدایت ہے اُن پرہیز گار لوگوں کے لیے",
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
      padding: const EdgeInsets.only(left: 8.0,
                      right: 8.0,),
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
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      // ignore: prefer_const_literals_to_create_immutables
                      children: <Widget>[
                        const Text(
                          "NAME OF MUHAMMAD",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
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

class SearchInQuaran extends StatelessWidget {
  SearchInQuaran({Key? key, this.today, this.size, this.bloc})
      : super(key: key);
  HijriCalendar? today;
  Size? size;
  ThemeProvider? bloc;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size!.width,
      // padding: EdgeInsets.symmetric(horizontal: 10),
      // color: Colors.red,
      child: Builder(builder: (context) {
        return Card(
          elevation: 5,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          color: bloc!.selectedSecondary,
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20),
            child: Column(
              children: [
                // CupertinoSearchTextField(
                //   borderRadius: BorderRadius.circular(20.0),
                //   backgroundColor: Colors.white,
                //   placeholder: "Search in Quran",
                //   prefixIcon: Image.asset(
                //     "assets/images/searchIcon.png",
                //     fit: BoxFit.cover,
                //     // height: 20,
                //     // width: 20,
                //   ),
                // ),

                const SizedBox(
                  height: 10,
                ),
                FittedBox(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_month,
                                color: bloc!.selectedTheme,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                "Date",
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: size!.height / 96,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                DateFormat('EEEE, d MMM, yyyy')
                                    .format(DateTime.now()),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.normal,
                                  // fontStyle: FontStyle.italic
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: size!.height / 96,
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: 20,
                                width: 20,
                              ),
                              const SizedBox(
                                width: 5,
                              ),
                              Text(
                                today!.toFormat("dd MMMM yyyy"),
                                style: TextStyle(
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.normal,
                                  // fontStyle: FontStyle.italic
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      /////////////////////////////////////
                      Container(
                        margin: EdgeInsets.only(left: 10),
                        color: Theme.of(context).primaryColor,
                        height: size!.height / 8,
                        width: 2,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_left_sharp,
                                  color: bloc!.selectedTheme,
                                  size: 30,
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  "Previous",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: size!.height / 96,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 12,
                                  width: 12,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Fajar",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.normal,
                                    // fontStyle: FontStyle.italic
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: size!.height / 96,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_right_sharp,
                                  color: bloc!.selectedTheme,
                                  size: 30,
                                ),
                                const SizedBox(
                                  width: 2,
                                ),
                                Text(
                                  "Next",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.w600,
                                    // fontStyle: FontStyle.italic
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                              height: size!.height / 96,
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  height: 12,
                                  width: 12,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  "Duhar",
                                  style: TextStyle(
                                    color: Theme.of(context).primaryColor,
                                    fontWeight: FontWeight.normal,
                                    // fontStyle: FontStyle.italic
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 20,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
