import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/kalma_dua_sheet.dart';
import 'package:iqra/Screens/MainPage/Khalima/khalimas_list.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:provider/provider.dart';

import '../../../Models/khalimas_model.dart';

class KhalimaScreen extends StatelessWidget {
  final List<KhalimasModel>? khalimaList;

  KhalimaScreen({super.key, this.khalimaList});

  @override
  Widget build(BuildContext context) {
    var khalimaList =
        this.khalimaList ?? khalimasModelFromJson(jsonEncode(khalimasData));

    Size size = MediaQuery.of(context).size;

    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Scaffold(
        backgroundColor: bloc.selectedSecondary,
        // floatingActionButton: floatinButton(context),
        // floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

        // extendBodyBehindAppBar: true,
        // bottomNavigationBar: BottomBarApp(bloc),
        appBar: AppBar(
          backgroundColor: bloc.selectedTheme,
          title: Text(
            "Kalima".toUpperCase(),
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          centerTitle: true,
          elevation: 0,
          leading: IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back)),
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/BgImage.png"),
                fit: BoxFit.cover,
              ),
            ),
            alignment: Alignment.center,
            width: size.width,
            height: size.height,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: ListView.builder(
                  itemCount: khalimaList.length,
                  itemBuilder: (context, index) {
                    KhalimasModel khalima = khalimaList[index];
                    return InkWell(
                      onTap: () {
                        final items = khalimaList
                            .map((k) => KDSData(
                                  title: k.meaning!,
                                  subtitle: k.title ?? "",
                                  arabic: k.arabic ?? "",
                                  translation: k.translation ?? "",
                                ))
                            .toList();
                        KalmaDuaSHEET.show(context, items, index, "KALIMA");
                      },
                      child: Container(
                        margin:
                            const EdgeInsets.only(left: 0, right: 0, top: 10),
                        padding: const EdgeInsets.all(15),
                        constraints: const BoxConstraints(minHeight: 80),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Theme.of(context).primaryColor,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              Icons.chevron_left_outlined,
                              size: 30,
                              color: MyColors.whiteColor,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${khalima.title}',
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontFamily: bloc.urduFontFamily,
                                        fontSize: 22,
                                        color: MyColors.whiteColor),
                                  ),
                                  if (khalima.meaning != null)
                                    Text(
                                      '${khalima.meaning}',
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                          fontFamily: bloc.urduFontFamily,
                                          fontSize: 16,
                                          color: MyColors.whiteColor
                                              .withOpacity(0.8)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ),
          ),
        ),
      );
    });
  }
}
