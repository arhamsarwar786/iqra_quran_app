// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Screens/MainPage/main_screen.dart';
import 'package:iqra/Screens/Permission/permission_screen.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late Animation<double> animation;
  late AnimationController controller;
  late Animation colorAnimation;

  @override
  void initState() {
    super.initState();
    // Use edge-to-edge mode to allow the background to cover status and navigation bars
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xff0E323F),
      systemNavigationBarIconBrightness: Brightness.light,
    ));

    Timer(const Duration(seconds: 3), () async {
      if (mounted) {
        final status = await Permission.location.status;
        if (status.isGranted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const MainScreen()));
        } else {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const PermissionScreen()));
        }
      }
    });

    controller =
        AnimationController(duration: const Duration(seconds: 5), vsync: this);
    animation = Tween<double>(begin: 150, end: 300).animate(controller);
    colorAnimation =
        ColorTween(begin: primayColor, end: secondaryColor).animate(controller);
    animation.addListener(() {
      setState(() {});
    });
    controller.forward();
  }

  @override
  void dispose() {
    // Restore normal UI mode when leaving splash
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xff0E323F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff0E323F),
        body: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              height: animation.value,
              width: animation.value,
              decoration: const BoxDecoration(
                  image: DecorationImage(
                      image: AssetImage(
                        'assets/images/logo.png',
                      ),
                      fit: BoxFit.fitWidth)),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(
                  "Developed By:  ",
                  style: TextStyle(color: Color.fromARGB(255, 155, 155, 155)),
                ),
                Text(
                  "Dev'sinnTechnologies",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15),
                ),
                SizedBox(
                  height: 200,
                )
              ]),
            ),
          ],
        ),
      ),
    );
  }
}
