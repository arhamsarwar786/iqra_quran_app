import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:iqra/Utils/utils.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Provider/theme_provider.dart';
import '../../../controller/methods.dart';
import '../../../Models/theme_model.dart';

var myColor = Color(0xff227C9E);

class SettingScreen extends StatefulWidget {
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  var value = "kgf";
  var color;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Setting"),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Select Theme:"),
            DropdownButton(
              icon: const Icon(Icons.keyboard_arrow_down),

              // Array list of items
              items: themeList.map((items) {
                return DropdownMenuItem(
                  value: items,
                  child: Text(
                    "theme Color",
                    style: TextStyle(color: items['primary']?.toColor(),fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
              // After selecting the desired option,it will
              // change button value to selected value
              onChanged: (Map? newValue) async {
                var theme = ThemeModel.fromJson(newValue!);
                ThemeProvider themeProvider =
                    Provider.of<ThemeProvider>(context, listen: false);
                themeProvider.changeTheme(theme.toJson());
                 snackBar(context, 'Theme Changed');
                setState(() {});
              },
            ),

            // Text("لآ اِلَهَ اِلّا اللّهُ مُحَمَّدٌ رَسُوُل اللّهِ",style: TextStyle(fontFamily: value,fontSize: 50),),
            // DropdownButton(
            //   // Initial Value
            //   // value: value,

            //   // Down Arrow Icon
            //   icon: const Icon(Icons.keyboard_arrow_down),

            //   // Array list of items
            //   items: fontFamilyList.map((items) {
            //     return DropdownMenuItem(
            //       value: items['fontFamily'],
            //       child: Text("${items['name']}"),
            //     );
            //   }).toList(),
            //   // After selecting the desired option,it will
            //   // change button value to selected value
            //   onChanged: (String? newValue) {
            //     value = newValue!;
            //     setState(() {});
            //   },
            // ),
          
          ],
        ),
      ),
    );
  }
}
