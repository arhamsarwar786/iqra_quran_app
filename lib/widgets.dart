import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'Provider/main_provider.dart';
import 'Screens/MainPage/main_screen.dart';
import 'Utils/constants.dart';

pushUntil(context, screen) {
  return Navigator.pushAndRemoveUntil(
      context, MaterialPageRoute(
        builder: (_) => screen), ((route) => false));
}

push(context, screen) {
  return Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
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
      color: primayColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: primayColor,
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
        pushUntil(context, MainScreen());
      },
      iconSize: 20,
      color: primayColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: primayColor,
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
      color: primayColor,
      icon: const Icon(Icons.arrow_back),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: primayColor,
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
floatinButton(context){
  return  FloatingActionButton(
          onPressed: () {
            // provider.screenIndex=0 ;
            pushUntil(context, MainScreen());
          },
          backgroundColor: const Color(0xff1B637E),
          child:
               FittedBox(
                  child: Column(
                    children: const [
                      Icon(Icons.home),
                      Text(
                        "Quran",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    ],
                  ),
                )
        );
}
void snackBar(BuildContext context,String text) {                                                                               
  final snackBar =  SnackBar(content:  Text(text,),                                                         
  backgroundColor: primayColor);                                                                                      

  // Find the Scaffold in the Widget tree and use it to show a SnackBar!                                            
  Scaffold.of(context).showSnackBar(snackBar); }
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