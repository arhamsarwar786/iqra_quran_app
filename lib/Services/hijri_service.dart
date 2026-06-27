import 'package:geocoding/geocoding.dart';
import 'package:hijri/hijri_calendar.dart';

class HijriService {
  static const Map<int, String> monthNames = {
    1: 'Muharram-ul-Haram',
    2: 'Safar-ul-Muzaffar',
    3: 'Rabi-ul-Awwal',
    4: 'Rabi-us-Sani',
    5: 'Jumada-ul-Awwal',
    6: 'Jumada-us-Sani',
    7: 'Rajab-ul-Murajab',
    8: 'Shaban-ul-Moazzam',
    9: 'Ramadan-ul-Mubarak',
    10: 'Shawwal-ul-Mukarram',
    11: 'Zilqad-tul-Haram',
    12: 'Zil-Hajj-tul-Haram',
  };

  static const Map<int, String> shortMonthNames = {
    1: 'Muharram',
    2: 'Safar',
    3: 'Rabi I',
    4: 'Rabi II',
    5: 'Jumada I',
    6: 'Jumada II',
    7: 'Rajab',
    8: 'Shaban',
    9: 'Ramadan',
    10: 'Shawwal',
    11: 'Zilqad',
    12: 'Zil Hajj',
  };

  static HijriCalendar toHijri(DateTime date, int offset) {
    return HijriCalendar.fromDate(date.add(Duration(days: offset)));
  }

  static String monthName(int month) =>
      monthNames[month] ?? HijriCalendar.fromDate(DateTime.now()).longMonthName;

  static String shortMonthName(int month) =>
      shortMonthNames[month] ?? monthName(month);

  static String fullLabel(HijriCalendar hijri) =>
      '${monthName(hijri.hMonth)} ${hijri.hYear} AH';

  static String rangeLabel(DateTime viewMonth, int offset) {
    final firstDay = DateTime(viewMonth.year, viewMonth.month, 1);
    final lastDay = DateTime(viewMonth.year, viewMonth.month + 1, 0);

    final hFirst = toHijri(firstDay, offset);
    final hLast = toHijri(lastDay, offset);

    if (hFirst.hMonth == hLast.hMonth) {
      return '${monthName(hFirst.hMonth)} ${hFirst.hYear}';
    }

    if (hFirst.hYear == hLast.hYear) {
      return '${monthName(hFirst.hMonth)} / ${monthName(hLast.hMonth)} ${hFirst.hYear}';
    }

    return '${monthName(hFirst.hMonth)} ${hFirst.hYear} / ${monthName(hLast.hMonth)} ${hLast.hYear}';
  }

  static Future<String?> countryFromCoordinates(
      double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final country = placemarks.first.country;
        if (country != null && country.isNotEmpty) return country;
      }
    } catch (_) {}
    return null;
  }

  static int regionalOffsetForCountry(String country) {
    final c = country.toLowerCase();
    if (c.contains('pakistan') ||
        c.contains('india') ||
        c.contains('bangladesh') ||
        c.contains('afghanistan') ||
        c.contains('sri lanka') ||
        c.contains('nepal')) {
      return -1;
    }
    return 0;
  }

  static int timezoneHeuristicOffset() {
    final offset = DateTime.now().timeZoneOffset;
    // Pakistan, India, Bangladesh, Sri Lanka, Nepal, parts of Central Asia
    if (offset.inHours >= 5 && offset.inHours <= 6) return -1;
    return 0;
  }

  /// Karachi / South-Asia prayer methods follow local moon-sighting (−1 day).
  static int offsetForCalculationMethod(String method) {
    switch (method) {
      case 'karachi':
        return -1;
      case 'makkah':
      case 'umm_al_qura':
      case 'dubai':
        return 0;
      default:
        return 0;
    }
  }

  /// Best auto offset: country → prayer method → device timezone.
  static int resolveAutoOffset({
    String? country,
    String calculationMethod = 'karachi',
  }) {
    if (country != null) {
      final regional = regionalOffsetForCountry(country);
      if (regional != 0) return regional;
    }

    final methodOffset = offsetForCalculationMethod(calculationMethod);
    if (methodOffset != 0) return methodOffset;

    return timezoneHeuristicOffset();
  }
}
