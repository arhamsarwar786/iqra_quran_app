import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPreferences {
  static setFav(items) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("quranFav", jsonEncode(items));
  }

  static getFav() async {
    var data;
    SharedPreferences pref = await SharedPreferences.getInstance();
    var res = pref.getString("quranFav");
    if (res != null) {
      data = jsonDecode(res);
    }
    return data;
  }

  static setBookmarkedAyats(items) async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.setString("quranAyatBookmarks", jsonEncode(items));
  }

  static getBookmarkedAyats() async {
    var data;
    SharedPreferences pref = await SharedPreferences.getInstance();
    var res = pref.getString("quranAyatBookmarks");
    if (res != null) {
      data = jsonDecode(res);
    }
    return data;
  }

  static clearFavPreference() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    await pref.clear();
    print("ALL CLEARED");
  }
}
