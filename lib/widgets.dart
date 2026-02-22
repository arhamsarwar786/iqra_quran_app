import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'Screens/MainPage/main_screen.dart';
import 'Screens/MainPage/Quran/tabbarview.dart';
import 'Screens/MainPage/Calendar/CalendarScreen.dart';

pushUntil(context, screen) {
  return Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(builder: (_) => screen), ((route) => false));
}

push(context, screen) {
  return Navigator.push(context, CupertinoPageRoute(builder: (_) => screen));
}

pop(context) {
  Navigator.pop(context);
}

customAppBar(BuildContext context, String title) {
  return AppBar(
    elevation: 5,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/BgImage.png"),
          fit: BoxFit.cover,
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      iconSize: 20,
      color: Theme.of(context).primaryColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).primaryColor,
      ),
    ),
  );
}

customRouteAppBar(BuildContext context, String title, Widget route) {
  return AppBar(
    elevation: 0,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/BgImage.png"),
          fit: BoxFit.cover,
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    leading: IconButton(
      onPressed: () {
        pushUntil(context, const MainScreen());
      },
      iconSize: 20,
      color: Theme.of(context).primaryColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).primaryColor,
      ),
    ),
  );
}

mainScreenAppBarPush(BuildContext context, String title) {
  return AppBar(
    elevation: 0,
    flexibleSpace: Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/BgImage.png"),
          fit: BoxFit.cover,
        ),
      ),
    ),
    backgroundColor: Colors.transparent,
    leading: IconButton(
      onPressed: () {
        Navigator.pop(context);
      },
      iconSize: 20,
      color: Theme.of(context).primaryColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).primaryColor,
      ),
    ),
  );
}

Widget bgImage(BuildContext context, Size size) {
  return Container(
    decoration: const BoxDecoration(
        image: DecorationImage(
            image: AssetImage(
              'assets/images/BgImage.png',
            ),
            fit: BoxFit.fill)),
  );
}

floatinButton(context) {
  final bloc = Provider.of<ThemeProvider>(context);
  return Transform.translate(
    offset: const Offset(0, 15), // Lift the entire assembly up by 10 pixels
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => push(context, TabBarDemo()),
          child: Container(
            height: 75,
            width: 75,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: AssetImage("assets/images/iqra${bloc.iconNumber}.png"),
                fit: BoxFit.contain,
              ),
              // gradient: LinearGradient(
              //   colors: [
              //     bloc.selectedTheme,
              //     bloc.selectedTheme.withOpacity(0.8),
              //   ],
              //   begin: Alignment.topLeft,
              //   end: Alignment.bottomRight,
              // ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: bloc.selectedTheme.withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 5), // Increased space from 6 to 10
        Text(
          "QURAN",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: bloc.selectedTheme,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

void snackBar(BuildContext context, String text) {
  final snackBar2 = SnackBar(
    content: Text(text),
    // backgroundColor: Theme.of(context).primaryColor,
    duration: const Duration(seconds: 1),
    // action: SnackBarAction(
    //   label:'Click',
    //   onPressed: () {
    //     print('Action is clicked');
    //   },
    //   textColor: Colors.white,
    //   disabledTextColor: Colors.grey,
    // ),
    onVisible: () {
      print('Snackbar is visible');
    },
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(10))),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
    padding: const EdgeInsets.all(15.0),
  );
  // Find the Scaffold in the Widget tree and use it to show a SnackBar!
  ScaffoldMessenger.of(context).showSnackBar(snackBar2);
}
// floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
// floatingActionButton: FloatingActionButton(
//   onPressed: () {
//     // provider.screenIndex=0 ;
//     push(context, MainScreen());
//   },
//   backgroundColor: const Color(0xff1B637E),
//   child: provider.screenIndex == 0
//       ? FittedBox(
//           child: Column(
//             children: const [
//               Icon(Icons.home),
//               Text(
//                 "Quran",
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//               )
//             ],
//           ),
//         )
//       : FittedBox(
//           child: Column(
//             children: const [
//               Icon(Icons.home),
//               Text(
//                 "Quran",
//                 style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w700,
//                   color: Colors.white,
//                 ),
//               )
//             ],
//           ),
//         ),
//   // child: ,
// ),
// bottomNavigationBar: buildMyNavBar(context),
// bottomNavigationBar:const BottomBarApp(),
