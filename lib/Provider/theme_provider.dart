import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Models/theme_model.dart';
import 'package:iqra/controller/methods.dart';


class ThemeProvider extends ChangeNotifier{
  // Color selectedTheme = Color(0xff227C9E);0E323F
  Color selectedTheme = Color(0xff0E323F);
  Color selectedSecondary = Color(0xffF2FCFF);
  Color selectedBackground = Colors.white;
  String iconNumber = "1";

  getSelectedTheme()async{
   var theme = await SavedPrefernces.getTheme();
   if(theme != null){
    var finded = ThemeModel.fromJson(theme);
    selectedTheme = finded.primary.toString().toColor();
    selectedSecondary = finded.secondary.toString().toColor();
    iconNumber = finded.iconNumber!;
    // print(theme.toString() + "0--------------------");
    // selectedBackground = finded.theme.toString().toColor();
    notifyListeners();
   }
  }
  
  changeTheme(theme){
    // selectedTheme = theme!.toString().toColor();
    SavedPrefernces.setTheme(theme);
    print(selectedTheme);
    notifyListeners();
  }
  }