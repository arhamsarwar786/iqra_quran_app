import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/controller/methods.dart';


class ThemeProvider extends ChangeNotifier{
  Color selectedTheme = Color(0xff227C9E);

  getSelectedTheme()async{
   var theme = await SavedPrefernces.getTheme();
   if(theme != null){
    selectedTheme = theme.toString().toColor();
    notifyListeners();
   }
  }
  
  changeTheme(theme){
    selectedTheme = theme!.toString().toColor();
    SavedPrefernces.setTheme(theme);
    print(selectedTheme);
    notifyListeners();
  }
  }