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

class SettingScreen extends StatefulWidget {
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  var value = "kgf";
  var color;

  @override
  void initState() {
    super.initState();
    arabicFontSize.clear();
    for (var i = 12; i <= 40; i++) {
      arabicFontSize.add(i.toDouble());
    }
    print(arabicFontSize);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      print(bloc.arabicFontSize);
      return Scaffold(
        backgroundColor: bloc.selectedSecondary,
        appBar: AppBar(
          title: const Text("Setting"),
          backgroundColor: Theme.of(context).primaryColor,
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              // mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Card(
                  child: Container(
                    height: 100,
                    width: size.width,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Theme Section",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              color: bloc.selectedTheme),
                        ),
                        Divider(
                          color: bloc.selectedTheme,
                        ),
                        Row(
                          children: [
                            Text(
                              "Theme",
                              style: MyTextStyle.heading3,
                            ),
                            const Spacer(),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1, color: bloc.selectedTheme)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                   hint: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text("Allah",style: TextStyle(
                                      color: bloc.selectedTheme
                                    ),),
                                  ),   
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: themeList.map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        "Allah",
                                        style: TextStyle(
                                            color: items['primary']?.toColor(),
                                            fontWeight: FontWeight.bold),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (Map? newValue) async {
                                    var theme = ThemeModel.fromJson(newValue!);
                                    ThemeProvider themeProvider =
                                        Provider.of<ThemeProvider>(context,
                                            listen: false);
                                    themeProvider.changeTheme(theme.toJson());
                                    snackBar(context, 'Theme Changed');
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Card(
                  child: Container(
                    height: 240,
                    width: size.width,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Arabic Font",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              color: bloc.selectedTheme),
                        ),
                        Divider(
                          color: bloc.selectedTheme,
                        ),
                        Row(
                          children: [
                            Text(
                              "Arabic Font",
                              style: MyTextStyle.heading3,
                            ),
                            const Spacer(),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1, color: bloc.selectedTheme)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                   hint: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text("${bloc.arabicFontFamily}"),
                                  ),   
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: arabicFontFamily.map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        items,
                                        style: MyTextStyle.heading3,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) async {
                                    
                                    bloc.changeArabicFamily(newValue);
                                    snackBar(context, 'Arabic Family Changed!');
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              "Font Size",
                              style: MyTextStyle.heading3,
                            ),
                            const Spacer(),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1, color: bloc.selectedTheme)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                   hint: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text("${bloc.arabicFontSize.toInt()}"),
                                  ),   
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: arabicFontSize.map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        "${items.toInt()}",
                                        style: MyTextStyle.heading3,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) async {
                                    bloc.changeArabicFont(newValue);
                                    snackBar(context, 'Arabic Font Changed!');
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        FittedBox(
                          child: Text(
                            "لآ اِلَهَ اِلّا اللّهُ مُحَمَّدٌ رَسُوُل اللّهِ",
                            style: TextStyle(fontSize: bloc.arabicFontSize,fontFamily: bloc.arabicFontFamily),
                          ),
                        )
                      ],
                    ),
                  ),
                ),

  ///////////////////////////////// URDU BLOCK 
                Card(
                  child: Container(
                    height: 240,
                    width: size.width,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Text(
                          "Urdu Font",
                          style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 20,
                              color: bloc.selectedTheme),
                        ),
                        Divider(
                          color: bloc.selectedTheme,
                        ),
                        Row(
                          children: [
                            Text(
                              "Urdu Font",
                              style: MyTextStyle.heading3,
                            ),
                            const Spacer(),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1, color: bloc.selectedTheme)),
                              child: DropdownButtonHideUnderline(                                
                                child: DropdownButton(
                                  hint: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text("${bloc.urduFontFamily}"),
                                  ),                                  
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: urduFontFamily.map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        items,
                                        style: MyTextStyle.heading3,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) async {
                                    
                                    bloc.changeUrduFamily(newValue);
                                    snackBar(context, 'Urdu Family Changed!');
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          children: [
                            Text(
                              "Font Size",
                              style: MyTextStyle.heading3,
                            ),
                            const Spacer(),
                            Container(
                              height: 40,
                              width: 150,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                      width: 1, color: bloc.selectedTheme)),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton(
                                   hint: Padding(
                                    padding: const EdgeInsets.only(left: 5),
                                    child: Text("${bloc.arabicFontSize.toInt()}"),
                                  ),   
                                  icon: const Icon(Icons.keyboard_arrow_down),
                                  items: arabicFontSize.map((items) {
                                    return DropdownMenuItem(
                                      value: items,
                                      child: Text(
                                        "${items.toInt()}",
                                        style: MyTextStyle.heading3,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) async {
                                    bloc.changeUrduFont(newValue);
                                    snackBar(context, 'Urdu Font Changed!');
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 20,
                        ),
                        FittedBox(
                          child: Text(
                            "تمام تعریف اللہ کے لیے ہے",
                            style: TextStyle(fontSize: bloc.urduFontSize,fontFamily: bloc.urduFontFamily),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                

              ],
            ),
          ),
        ),
      );
    });
  }
}
