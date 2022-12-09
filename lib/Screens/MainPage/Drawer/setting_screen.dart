import 'package:flutter/material.dart';
import 'package:iqra/Utils/utils.dart';
class SettingScreen extends StatefulWidget {
  
  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  var value = "kgf";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
        Text("لآ اِلَهَ اِلّا اللّهُ مُحَمَّدٌ رَسُوُل اللّهِ",style: TextStyle(fontFamily: value,fontSize: 50),)
        ,DropdownButton(
               
              // Initial Value
              // value: value,
               
              // Down Arrow Icon
              icon: const Icon(Icons.keyboard_arrow_down),   
               
              // Array list of items
              items: fontFamilyList.map((items) {
                return DropdownMenuItem(
                  value: items['fontFamily'],
                  child: Text("${items['name']}"),
                );
              }).toList(),
              // After selecting the desired option,it will
              // change button value to selected value
              onChanged: (String? newValue) {
                  value = newValue!;
                setState(() {
                });
              },
            ),

      ],),
    );
  }
}