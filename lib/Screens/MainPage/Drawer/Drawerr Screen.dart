// import 'dart:ffi';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/rendering.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Drawer/setting_screen.dart';
import 'package:provider/provider.dart';
import '../../../Utils/constants.dart';
import '../../../widgets.dart';
import '../Dua/dua_screen.dart';
import '../Khalima/kalma_screen.dart';
import '../Quran/Favorite.dart';
import '../Quran/tabbarview.dart';
import '../Tasbeeh/tasbee_detail.dart';
import 'About Us.dart';
import 'ContactUs.dart';

// import 'contactUs.dart';

class Darwerr extends StatefulWidget {
  @override
  _DarwerrState createState() => _DarwerrState();
}

class _DarwerrState extends State<Darwerr> with SingleTickerProviderStateMixin {
  static const _menuTitles = [
    'Favourite',
    'Quran',
    'Kalima',
    'Dua',
    'Tasbeeh',
    'Contact Us',
    'About Us',
    'Setting',
    'Share',
  ];
  static const _icons = [
    Icons.favorite,
    Icons.menu_book,
    Icons.list,
    Icons.handshake,
    Icons.ads_click,
    Icons.contacts_sharp,
    Icons.info_outline_rounded,
    Icons.settings,
    Icons.share    
  ];
  List _navigationSc = [
    Favorite(),
    TabBarDemo(),
    KhalimaScreen(),
    DuaScreen(),
    TasbeeDetail(),
    Contactus(),
    Aboutus(),
    SettingScreen(),
  ];
  static const _initialDelayTime = Duration(milliseconds: 50);
  static const _itemSlideTime = Duration(milliseconds: 600);
  static const _staggerTime = Duration(milliseconds: 50);
  static const _buttonDelayTime = Duration(milliseconds: 150);
  static const _buttonTime = Duration(milliseconds: 500);
  final _animationDuration = _initialDelayTime +
      (_staggerTime * _menuTitles.length) +
      _buttonDelayTime +
      _buttonTime;

  late AnimationController _staggeredController;
  final List<Interval> _itemSlideIntervals = [];
  late Interval _buttonInterval;

  @override
  void initState() {
    super.initState();

    _createAnimationIntervals();

    _staggeredController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    )..forward();
  }

  void _createAnimationIntervals() {
    for (var i = 0; i < _menuTitles.length; ++i) {
      final startTime = _initialDelayTime + (_staggerTime * i);
      final endTime = startTime + _itemSlideTime;
      _itemSlideIntervals.add(
        Interval(
          startTime.inMilliseconds / _animationDuration.inMilliseconds,
          endTime.inMilliseconds / _animationDuration.inMilliseconds,
        ),
      );
    }
  }

  @override
  void dispose() {
    _staggeredController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Builder(
      builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Container(
          width: size.width * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            children: [
              Consumer<ThemeProvider>(
                builder: (context,provider,child) {
                  return SizedBox(
                    width: double.infinity,
                    child: Container(
                      height: 200,
                      padding: EdgeInsets.all(20),
                      // width: MediaQuery.of(context).size.width * 0.60,
                     child: Image.asset("assets/images/iqra${provider.iconNumber}.png",fit: BoxFit.fitHeight,),
                    ),
                  );
                }
              ),
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: _menuTitles.length,
                  itemBuilder: (context, i) {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _staggeredController,
                            builder: (context, child) {
                              final animationPercent = Curves.easeOut.transform(
                                _itemSlideIntervals[i]
                                    .transform(_staggeredController.value),
                              );
                              final opacity = animationPercent;
                              final slideDistance = (1 - animationPercent) * 150;

                              return Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(slideDistance, 0),
                                  child: child,
                                ),
                              );
                            },
                            child: Card(
                              elevation: 3,
                              child: ListTile(
                                dense: true,
                                leading: Container(
                                  height: 30,
                                  width: 30,
                                 child: Icon(_icons[i],color: bloc.selectedTheme,),
                                ),
                                selectedTileColor:const Color(0xff00164C),
                                onTap: () {
                               push(context, _navigationSc[i]);
                                },
                                title: Text(
                                  _menuTitles[i],
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xff00164C),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ],
          ),
        );
      }
    );
  }
}
