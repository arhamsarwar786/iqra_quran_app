import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  return Container(
    margin: const EdgeInsets.only(top: 30),
    child: GestureDetector(
      onTap: () => push(context, const TabBarDemo()),
      child: Container(
        height: 70,
        width: 70,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
            Text(
              "QURAN",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
