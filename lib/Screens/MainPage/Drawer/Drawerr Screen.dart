// import 'dart:ffi';
import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Drawer/setting_screen.dart';
import 'package:iqra/Screens/MainPage/Tasbeeh/tasbee.dart';
import 'package:provider/provider.dart';
import '../../../widgets.dart';
import '../Dua/dua_screen.dart';
import '../Khalima/kalma_screen.dart';
import '../Quran/Favorite.dart';
import '../Quran/tabbarview.dart';
import 'About Us.dart';
import 'ContactUs.dart';
import 'package:iqra/Utils/sadqa_dialog.dart';
import 'package:share_plus/share_plus.dart';

// import 'contactUs.dart';

class Darwerr extends StatefulWidget {
  const Darwerr({super.key});

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
    // 'Contact Us',
    'About Us',
    'Setting',
    'Donate 🤍',
    'Share',
  ];
  static const _icons = [
    Icons.favorite,
    Icons.menu_book,
    Icons.list,
    Icons.handshake,
    Icons.ads_click,
    // Icons.contacts_sharp,
    Icons.info_outline_rounded,
    Icons.settings,
    Icons.volunteer_activism_rounded,
    Icons.share,
  ];
  final List _navigationSc = [
    const Favorite(),
    TabBarDemo(),
    KhalimaScreen(),
    const DuaScreen(),
    const Tasbih(),
    // const Contactus(),
    const Aboutus(),
    const SettingScreen(),
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
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return SafeArea(
        bottom: false,
        child: Container(
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
              // ── Logo Header ─────────────────────────────────────────────
              Consumer<ThemeProvider>(builder: (context, provider, child) {
                return Container(
                  width: double.infinity,
                  height: 180,
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    "assets/images/iqra${provider.iconNumber}.png",
                    fit: BoxFit.fitHeight,
                  ),
                );
              }),
              const Divider(height: 1, thickness: 1),
              // ── Scrollable Menu ──────────────────────────────────────────
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 6, bottom: 20),
                  itemCount: _menuTitles.length,
                  itemBuilder: (context, i) {
                    return AnimatedBuilder(
                      animation: _staggeredController,
                      builder: (context, child) {
                        final animationPercent = Curves.easeOut.transform(
                          _itemSlideIntervals[i]
                              .transform(_staggeredController.value),
                        );
                        final opacity = animationPercent.clamp(0.0, 1.0);
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
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 2),
                          leading: Icon(
                            _icons[i],
                            color: i == 7
                                ? bloc.selectedTheme
                                : bloc.selectedTheme,
                            size: 24,
                          ),
                          selectedTileColor: const Color(0xff00164C),
                          onTap: () {
                            // Index 8 = Donate → show Sadqa Jariya dialog
                            if (i == 7) {
                              Navigator.of(context).pop();
                              Future.delayed(
                                const Duration(milliseconds: 250),
                                () => SadqaDialog.show(context),
                              );
                            } else if (i == 8) {
                              Navigator.of(context).pop();
                              Share.share(
                                  "Download IQRA QURAN App: https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran");
                            } else if (i < _navigationSc.length) {
                              push(context, _navigationSc[i]);
                            }
                          },
                          title: Text(
                            _menuTitles[i],
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              color: i == 8
                                  ? bloc.selectedTheme
                                  : const Color(0xff00164C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
