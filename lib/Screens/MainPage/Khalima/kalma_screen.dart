import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Home/HomeScreen.dart';
import 'package:iqra/Screens/MainPage/Khalima/kalma_view.dart';
import 'package:iqra/Screens/MainPage/Khalima/khalimas_list.dart';
import 'package:iqra/Screens/MainPage/Khalima/widgets.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../Models/khalimas_model.dart';
import '../../../widgets.dart';
import '../main_screen.dart';

class KhalimaScreen extends StatelessWidget {
  List<KhalimasModel>? khalimaList;

  @override
  Widget build(BuildContext context) {
    khalimaList = khalimasModelFromJson(jsonEncode(khalimasData));

    Size size = MediaQuery.of(context).size;
   
    return Builder(
      builder: (context) {
        var bloc = context.read<ThemeProvider>();
        return Scaffold(
          backgroundColor: bloc.selectedSecondary,
                      floatingActionButton: floatinButton(context),
 floatingActionButtonLocation:
                FloatingActionButtonLocation.centerDocked,
                 bottomNavigationBar: BottomBarApp(bloc:bloc,isShow: false,),
            extendBodyBehindAppBar: true,
                      // bottomNavigationBar: BottomBarApp(bloc),
          appBar: AppBar(
            backgroundColor: bloc.selectedTheme,
            title: const Text(
              "Kalma",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
                onPressed: () {
               Navigator.pop(context);
                },
                icon: Icon(Icons.arrow_back)),
          ),
          body: Container(
            alignment: Alignment.center,
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),        
            child: Center(
              child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 3.3 / 2.5,
                  ),
                  itemCount: khalimaList!.length,
                  itemBuilder: (context, index) {
                    KhalimasModel khalima = khalimaList![index];
                    return GestureDetector(
                      onTap: () {
                        push(context, KhalimaView(khalima));
                      },
                      child: Stack(
                        children: [
                          Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              boxShadow: kElevationToShadow[4],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  khalima.title!,
                                  style: TextStyle(
                                    color:MyColors. whiteColor,
                                    // fontSize: 20,

                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  khalima.meaning!,
                                  style: TextStyle(
                                    fontFamily:"alQalam",
                                    color:MyColors. whiteColor,
                                    // fontSize: 20,

                                    fontWeight: FontWeight.normal,
                                  ),
                                )
                              ],
                            ),
                          ),
                          CustomBorders(
                            image: "ktopleft.png",
                            top: 10,
                            left: 10,
                          ),
                          CustomBorders(
                            image: "ktopright.png",
                            top: 10,
                            right: 10,
                          ),
                          CustomBorders(
                            image: "kbottomleft.png",
                            bottom: 10,
                            left: 10,
                          ),
                          CustomBorders(
                            image: "kbottomright.png",
                            bottom: 10,
                            right: 10,
                          ),
                        ],
                      ),
                    );
                  }),
            ),
          ),
        );
      }
    );
  }
}