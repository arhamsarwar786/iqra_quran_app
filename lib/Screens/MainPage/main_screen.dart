import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Provider/main_provider.dart';
import '../../Provider/theme_provider.dart';
import '../../Utils/constants.dart';
import '../../widgets.dart';
import 'Dua/dua_screen.dart';
import 'Home/HomeScreen.dart';
import 'Khalima/kalma_screen.dart';
import 'Quran/tabbarview.dart';
import 'Tasbeeh/tasbee_detail.dart';

List<Widget> screens = [
  const Home(),
  const DuaScreen(),
];

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    MyProvider provider = Provider.of<MyProvider>(context, listen: false);
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Consumer<MyProvider>(builder: (context, provider, child) {
          return const Home();
        }),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: MaterialButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {},
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    )),
              ),
            ],
          ),
        )) ??
        false;
  }
}

////BottomApp Bar created by Abdul Wahab//////
class BottomBarApp extends StatelessWidget {
  final ThemeProvider? bloc;
  const BottomBarApp(this.bloc);

  @override
  Widget build(BuildContext context) {
    MyProvider provider = Provider.of<MyProvider>(context, listen: false);
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 50),
        height: 45,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () {
                push(context, TabBarDemo());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 24,
                    width: 18,
                    decoration: BoxDecoration(
                        // color: Colors.red,
                        image: DecorationImage(
                            image: AssetImage("assets/images/Tasbi${bloc!.iconNumber}.png"),
                            fit: BoxFit.fill)),
                  ),
                  Text(
                    "Quran",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MyColors.greyColor,
                    ),
                  )
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                // push(context, TabBarDemo());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 26,
                    width: 27,
                    decoration: const BoxDecoration(
                        image: DecorationImage(
                            image: AssetImage("assets/images/hadees.png"),
                            fit: BoxFit.fill),
                            ),
                  ),
                  Text(
                    " Hadees",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: MyColors.greyColor,
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
