import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPrefernces {
  static setTheme(theme) async {
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('theme', jsonEncode(theme));
  }

  static getTheme() async {
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var theme = pref.getString('theme');
    if (theme != null) {
      data = jsonDecode(theme);
    }
    return data;
  }

  ///// Arabic Font Family
  static setArabicFontFamily(theme) async {
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('arabicFamily', jsonEncode(theme));
  }

  static getArabicFontFamily() async {
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var fontFamily = pref.getString('arabicFamily');
    if (fontFamily != null) {
      data = jsonDecode(fontFamily);
    }
    return data;
  }

  ///// Arabic Font Size
  static setArabicFontSize(theme) async {
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('arabicSize', jsonEncode(theme));
  }

  static getArabicFontSize() async {
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var fontSize = pref.getString('arabicSize');
    if (fontSize != null) {
      data = jsonDecode(fontSize);
    }
    return data;
  }

  ///// Urdu Font Size
  static setUrduFontSize(theme) async {
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('urduSize', jsonEncode(theme));
  }

  static getUrduFontSize() async {
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var fontSize = pref.getString('urduSize');
    if (fontSize != null) {
      data = jsonDecode(fontSize);
    }
    return data;
  }


    static setUrduFontFamily(theme) async {
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    pref.setString('urduFamily', jsonEncode(theme));
  }

  static getUrduFontFamily() async {
    var data;
    final pref = await SharedPreferences.getInstance();
    pref.reload();
    var fontFamily = pref.getString('urduFamily');
    if (fontFamily != null) {
      data = jsonDecode(fontFamily);
    }
    return data;
  }

}
