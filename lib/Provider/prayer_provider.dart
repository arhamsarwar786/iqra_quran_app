import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:intl/intl.dart';
import '../Helper/preference/saved_preferences.dart';
import '../Services/prayer_notification_service.dart';
import '../Services/analytics_service.dart';

class PrayerProvider extends ChangeNotifier {
  Map<String, dynamic>? _prayerData;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get prayerData => _prayerData;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPrayerData({bool forceRefresh = false}) async {
    if (_prayerData != null && !forceRefresh) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      AnalyticsService.trackPrayerTimeCheck();
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services are disabled.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw 'Location permissions are denied';
      }

      if (permission == LocationPermission.deniedForever)
        throw 'Location permissions are permanently denied.';

      // Prioritize last known position for fast loading
      Position? position = await Geolocator.getLastKnownPosition();

      if (position == null) {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 5),
        );
      }

      final String madhab = await SavedPrefernces.getMadhab();
      final String calcMethod = await SavedPrefernces.getCalculationMethod();
      final bool notificationsEnabled =
          await SavedPrefernces.getPrayerNotificationsEnabled();

      String locationName = "Location Detected";
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          locationName =
              "${place.locality ?? place.subAdministrativeArea}, ${place.country}";
        }
      } catch (e) {
        // Fallback for geocoding error
      }

      Coordinates coordinates =
          Coordinates(position.latitude, position.longitude);
      CalculationParameters params;
      switch (calcMethod) {
        case 'karachi':
          params = CalculationMethodParameters.karachi();
          break;
        case 'mwl':
          params = CalculationMethodParameters.muslimWorldLeague();
          break;
        case 'isna':
          params = CalculationMethodParameters.northAmerica();
          break;
        case 'egypt':
          params = CalculationMethodParameters.egyptian();
          break;
        case 'makkah':
        case 'umm_al_qura':
          params = CalculationMethodParameters.ummAlQura();
          break;
        case 'dubai':
          params = CalculationMethodParameters.dubai();
          break;
        case 'turkey':
        case 'turkiye':
          params = CalculationMethodParameters.turkiye();
          break;
        case 'tehran':
          params = CalculationMethodParameters.tehran();
          break;
        case 'singapore':
          params = CalculationMethodParameters.singapore();
          break;
        default:
          params = CalculationMethodParameters.karachi();
      }
      params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

      // Use local now to ensure calculations are for the current local day
      final DateTime nowLocal = DateTime.now();
      PrayerTimes pt = PrayerTimes(
          coordinates: coordinates,
          date: nowLocal,
          calculationParameters: params,
          precision: true);

      DateTime tomorrowLocal = nowLocal.add(const Duration(days: 1));
      PrayerTimes ptTomorrow = PrayerTimes(
          coordinates: coordinates,
          date: tomorrowLocal,
          calculationParameters: params,
          precision: true);

      // Filtered lists
      final List<Map<String, dynamic>> timesList = [];
      final List<Map<String, dynamic>> fardList = [];

      void add(String name, DateTime? time, bool fard) {
        if (time == null) return;

        // adhan_dart results are typically relative to the date passed.
        // We ensure they are treated as local times for the UI.
        final DateTime displayTime = time.toLocal();

        final entry = {
          "name": name,
          "time": DateFormat("h:mm a").format(displayTime),
          "dateTime": displayTime,
          "isFard": fard,
        };
        timesList.add(entry);
        if (fard) fardList.add(entry);
      }

      // Add Farz
      add("Fajr", pt.fajr, true);
      add("Zuhr", pt.dhuhr, true);
      add("Asr", pt.asr, true);
      add("Maghrib", pt.maghrib, true);
      add("Isha", pt.isha, true);

      // Add Optionals
      add("Ishraq", pt.sunrise.add(const Duration(minutes: 15)), false);
      add("Chasht", pt.sunrise.add(const Duration(hours: 2, minutes: 15)),
          false);
      add("Awwabin", pt.maghrib.add(const Duration(minutes: 15)), false);
      add("Witr", pt.isha.add(const Duration(minutes: 30)), false);

      Duration night = ptTomorrow.fajr.difference(pt.maghrib);
      add(
          "Tahajjud",
          pt.maghrib.add(Duration(seconds: (night.inSeconds * 0.75).toInt())),
          false);

      timesList.sort((a, b) =>
          (a["dateTime"] as DateTime).compareTo(b["dateTime"] as DateTime));
      fardList.sort((a, b) =>
          (a["dateTime"] as DateTime).compareTo(b["dateTime"] as DateTime));

      _prayerData = {
        "location": locationName,
        "timesList": timesList,
        "fardList": fardList,
        "sunrise": pt.sunrise.toLocal(),
        "nextFajr": ptTomorrow.fajr.toLocal(),
        "position": position,
      };

      if (notificationsEnabled) {
        try {
          await PrayerNotificationService.scheduleAllPrayers(
            position: position,
            madhab: madhab,
          );
        } catch (e) {
          debugPrint("Error scheduling notifications: $e");
        }
      }

      _isLoading = false;
      notifyListeners();

      // Trigger a refresh in the background for higher accuracy
      if (!forceRefresh) {
        _refreshAccuracyInBackground(params, madhab, notificationsEnabled);
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _refreshAccuracyInBackground(CalculationParameters params,
      String madhab, bool notificationsEnabled) async {
    try {
      await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );

      // Refresh to ensure accuracy
      fetchPrayerData(forceRefresh: true);
    } catch (_) {}
  }
}
