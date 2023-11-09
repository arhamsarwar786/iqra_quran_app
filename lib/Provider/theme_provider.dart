import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Models/theme_model.dart';
import 'package:iqra/controller/methods.dart';

class ThemeProvider extends ChangeNotifier {
  // Color selectedTheme = Color(0xff227C9E);0E323F
  Color selectedTheme = Color(0xff0E323F);
  Color selectedSecondary = Color(0xffF2FCFF);
  Color selectedBackground = Colors.white;
  String iconNumber = "1";

  ////  FONT STYLES  ////
  // Arabic
  String arabicFontFamily = "AlQalamQuranMajeed";
  var arabicFontSize = 30.0;
  // Urdu
  String urduFontFamily = "nastaleeq";
var urduFontSize = 25.0;

  getSelectedTheme() async {
    var theme = await SavedPrefernces.getTheme();
    if (theme != null) {
      var finded = ThemeModel.fromJson(theme);
      selectedTheme = finded.primary.toString().toColor();
      selectedSecondary = finded.secondary.toString().toColor();
      iconNumber = finded.iconNumber!;
      notifyListeners();
    }
  }

  changeTheme(theme) {
    SavedPrefernces.setTheme(theme);
    notifyListeners();
  }

  /// Arabic Font
  getSelectedArabicFont() async {
    var data = await SavedPrefernces.getArabicFontSize();
    if (data != null) {
      arabicFontSize = data;
      notifyListeners();
    }
  }

  changeArabicFont(data) {
    SavedPrefernces.setArabicFontSize(data);
    getSelectedArabicFont();
  }

  /// Arabic Font Family
  getSelectedArabicFamily() async {
    var data = await SavedPrefernces.getArabicFontFamily();
    if (data != null) {
      arabicFontFamily = data;
      notifyListeners();
    }
  }

  changeArabicFamily(data) {
    SavedPrefernces.setArabicFontFamily(data);
    getSelectedArabicFamily();
  }

  /// Urdu Font
  getSelectedUrduFont() async {
    var data = await SavedPrefernces.getUrduFontSize();
    if (data != null) {
      urduFontSize = data;
      notifyListeners();
    }
  }

  changeUrduFont(data) {
    SavedPrefernces.setUrduFontSize(data);
    getSelectedUrduFont();
  }

  /// Urdu Font Family
  getSelectedUrduFamily() async {
    var data = await SavedPrefernces.getUrduFontFamily();
    if (data != null) {
      urduFontFamily = data;
      notifyListeners();
    }
  }

  changeUrduFamily(data) {
    SavedPrefernces.setUrduFontFamily(data);
    getSelectedUrduFamily();
  }
}
