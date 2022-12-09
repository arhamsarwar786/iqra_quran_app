import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';


class SavedPreferences {
  static setFav(items)async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.setString("quranFav", jsonEncode(items));
  }

  static getFav()async{
    var data;
    SharedPreferences pref = await SharedPreferences.getInstance();
    var res = pref.getString("quranFav");
    if(res != null){
      data = jsonDecode(res);
    }
    return data;
  }


  static clearFavPreference()async{
    SharedPreferences pref = await SharedPreferences.getInstance();
    pref.clear();
    print("ALL CLEARED");
  }

}