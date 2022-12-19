import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPrefernces{

  static setTheme(theme)async{
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('theme', jsonEncode(theme));
  }

  static getTheme()async{
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var theme = pref.getString('theme');
    if(theme != null){
      data = jsonDecode(theme);
    }
    return data;
  }

}