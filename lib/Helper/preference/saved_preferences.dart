import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SavedPrefernces {
  static setTheme(theme) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('theme', jsonEncode(theme));
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
    await pref.setString('arabicFamily', jsonEncode(theme));
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
    await pref.setString('arabicSize', jsonEncode(theme));
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
    await pref.setString('urduSize', jsonEncode(theme));
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
    await pref.setString('urduFamily', jsonEncode(theme));
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

  ///// Madhab (Fiqa)
  static setMadhab(String madhab) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('madhab', madhab);
  }

  static Future<String> getMadhab() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('madhab') ?? 'hanafi';
  }

  ///// Prayer Notifications
  static setPrayerNotificationsEnabled(bool enabled) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('prayer_notifications_enabled', enabled);
  }

  static Future<bool> getPrayerNotificationsEnabled() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('prayer_notifications_enabled') ?? true;
  }

  ///// Prayer Notifications — per-prayer toggles
  static const List<String> prayerKeys = [
    'fajr',
    'zuhr',
    'asr',
    'maghrib',
    'isha'
  ];

  static Future<void> setPrayerNotificationEnabled(
      String prayer, bool enabled) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('notif_$prayer', enabled);
  }

  static Future<bool> getPrayerNotificationEnabled(String prayer) async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('notif_$prayer') ?? true;
  }

  /// Returns a map like {'fajr': true, 'zuhr': false, ...}
  static Future<Map<String, bool>> getAllPrayerNotificationToggles() async {
    final pref = await SharedPreferences.getInstance();
    return {
      for (final k in prayerKeys) k: pref.getBool('notif_$k') ?? true,
    };
  }

  ///// Custom Azan Sound
  static Future<void> setCustomAzanPath(String? path) async {
    final pref = await SharedPreferences.getInstance();
    if (path == null) {
      await pref.remove('custom_azan_path');
    } else {
      await pref.setString('custom_azan_path', path);
    }
  }

  static Future<String?> getCustomAzanPath() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('custom_azan_path');
  }

  ///// Calculation Method
  static Future<void> setCalculationMethod(String method) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('calc_method', method);
  }

  static Future<String> getCalculationMethod() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('calc_method') ?? 'karachi';
  }

  ///// Last Read Tracking
  static setLastRead(Map<String, dynamic> lastReadData) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('lastRead', jsonEncode(lastReadData));
  }

  static Future<Map<String, dynamic>?> getLastRead() async {
    final pref = await SharedPreferences.getInstance();
    String? data = pref.getString('lastRead');
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  static updateLastReadOffset(double offset) async {
    final pref = await SharedPreferences.getInstance();
    String? data = pref.getString('lastRead');
    if (data != null) {
      Map<String, dynamic> lastReadData = jsonDecode(data);
      lastReadData['scrollOffset'] = offset;
      await pref.setString('lastRead', jsonEncode(lastReadData));
    }
  }

  ///// Translation Selection
  static setSelectedTranslation(String? type) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('selectedTranslation', type ?? 'irfan');
  }

  static Future<String> getSelectedTranslation() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('selectedTranslation') ?? 'irfan';
  }

  ///// Hijri Offset
  static setHijriOffset(int offset) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setInt('hijri_offset', offset);
  }

  static Future<int> getHijriOffset() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getInt('hijri_offset') ?? 0;
  }

  static setHijriManual(bool isManual) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('hijri_manual', isManual);
  }

  static Future<bool> getHijriManual() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('hijri_manual') ?? false;
  }

  static setLastCountry(String country) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setString('last_country', country);
  }

  static Future<String?> getLastCountry() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString('last_country');
  }
}
