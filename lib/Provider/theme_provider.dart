import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Models/theme_model.dart';
import 'package:iqra/controller/methods.dart';
import 'package:iqra/Services/analytics_service.dart';

class ThemeProvider extends ChangeNotifier {
  // Color selectedTheme = Color(0xff227C9E);0E323F
  Color selectedTheme = const Color(0xff227C9E);
  Color selectedSecondary = const Color(0xffF2FCFF);
  Color selectedBackground = Colors.white;
  String iconNumber = "2";

  ThemeProvider() {
    _init();
  }

  ////  FONT STYLES  ////
  // Arabic
  String arabicFontFamily = "AlQalamQuranMajeed";
  var arabicFontSize = 30.0;
  // Urdu
  String urduFontFamily = "nastaleeq";
  var urduFontSize = 25.0;

  Future<void> _init() async {
    await getSelectedTheme();
    await getSelectedArabicFont();
    await getSelectedArabicFamily();
    await getSelectedUrduFont();
    await getSelectedUrduFamily();
    await getSelectedTranslation();
    await getHijriOffset();
  }

  static MaterialColor createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

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
    AnalyticsService.trackSettingChange('theme', theme);
    SavedPrefernces.setTheme(theme);
    var finded = ThemeModel.fromJson(theme);
    selectedTheme = finded.primary.toString().toColor();
    selectedSecondary = finded.secondary.toString().toColor();
    iconNumber = finded.iconNumber!;
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
    AnalyticsService.trackSettingChange('arabic_font_size', data);
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

  /// Translation
  String selectedTranslation =
      "irfan"; // irfan or hind (irfan: Kanz-ul-Irfan, hind: Kanz-ul-Iman)

  getSelectedTranslation() async {
    var data = await SavedPrefernces.getSelectedTranslation();
    // Migrate old keys to standard 'hind' key
    if (data == "furqan" || data == "iman") {
      data = "hind";
      SavedPrefernces.setSelectedTranslation(data);
    }
    selectedTranslation = data;
    notifyListeners();
  }

  changeTranslation(data) {
    AnalyticsService.trackSettingChange('translation', data);
    SavedPrefernces.setSelectedTranslation(data);
    getSelectedTranslation();
  }

  /// Hijri Offset
  int hijriOffset = 0;
  bool isHijriManual = false;

  getHijriOffset() async {
    isHijriManual = await SavedPrefernces.getHijriManual();
    int savedOffset = await SavedPrefernces.getHijriOffset();

    if (!isHijriManual) {
      String? lastCountry = await SavedPrefernces.getLastCountry();
      if (lastCountry != null) {
        _applyRegionalOffset(lastCountry);
      } else {
        // Timezone heuristic for first-time use OR when location is unavailable
        final hours = DateTime.now().timeZoneOffset.inHours;
        if (hours >= 5) {
          hijriOffset = -1; // Best guess for Pakistan/India/Bangladesh
        } else {
          hijriOffset = 0;
        }
      }
    } else {
      hijriOffset = savedOffset;
    }
    notifyListeners();
  }

  changeHijriOffset(int data) async {
    isHijriManual = true;
    await SavedPrefernces.setHijriManual(true);
    await SavedPrefernces.setHijriOffset(data);
    hijriOffset = data;
    notifyListeners();
  }

  /// Auto-adjust Hijri based on location/country
  void updateHijriAutoAdjust(String country) {
    if (isHijriManual) return;
    SavedPrefernces.setLastCountry(country);
    _applyRegionalOffset(country);
  }

  void _applyRegionalOffset(String country) {
    int newOffset = 0;
    final c = country.toLowerCase();

    // Pakistan, India, Bangladesh are usually 1 day behind Saudi (Umm al-Qura)
    if (c.contains('pakistan') ||
        c.contains('india') ||
        c.contains('bangladesh')) {
      newOffset = -1;
    }
    // Add more regions here if known patterns exist

    if (hijriOffset != newOffset) {
      hijriOffset = newOffset;
      SavedPrefernces.setHijriOffset(newOffset);
      notifyListeners();
    }
  }
}
