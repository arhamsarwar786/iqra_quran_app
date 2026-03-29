import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tz_lookup;
import '../Helper/preference/saved_preferences.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// Prayer key → display name helper
/// ─────────────────────────────────────────────────────────────────────────────
const Map<String, String> prayerDisplayNames = {
  'fajr': 'Fajr',
  'zuhr': 'Zuhr',
  'asr': 'Asr',
  'maghrib': 'Maghrib',
  'isha': 'Isha',
};

const Map<String, int> prayerNotifIds = {
  'fajr': 1,
  'zuhr': 2,
  'asr': 3,
  'maghrib': 4,
  'isha': 5,
};

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // ─── initialise ──────────────────────────────────────────────────────────
  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTapped,
    );

    // Request Android 13+ notification permission
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // Check for exact alarm permission on Android 12+ (API 31+)
    // This is optional but helpful to ensure zonedSchedule works correctly
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    _initialized = true;
  }

  static void _onTapped(NotificationResponse r) {
    // Could navigate to PrayerTime screen
  }

  // ─── build CalculationParameters from saved method + madhab ─────────────
  static Future<CalculationParameters> _buildParams() async {
    final method = await SavedPrefernces.getCalculationMethod();
    final madhab = await SavedPrefernces.getMadhab();

    CalculationParameters params;
    switch (method) {
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
    return params;
  }

  // ─── Returns the Android notification details ────────────────────────────
  // IMPORTANT: Changing channel ID (e.g., from 'prayer_notifications' to 'prayer_notifications_high')
  // is NECESSARY if you want to ensure sound plays on devices where the channel was already
  // created with lower importance or no sound previously.
  static Future<AndroidNotificationDetails> _androidDetails(
      String prayerName) async {
    // Bundled azan.mp3 in res/raw
    return AndroidNotificationDetails(
      'prayer_notifications_high_v2', // Updated ID to ensure high importance/sound on existing devices
      'Prayer Alerts',
      channelDescription: 'Adhan sound notifications for daily prayer times',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('azan'),
      enableVibration: true,
      audioAttributesUsage: AudioAttributesUsage.alarm, // Important for sound on some devices
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        'وقت نماز $prayerName آ گیا',
        contentTitle: '🕌 $prayerName — نماز کا وقت',
      ),
    );
  }

  // ─── Send a test notification immediately ────────────────────────────────
  static Future<void> sendTestNotification() async {
    await initialize();
    final details = await _androidDetails('Test');
    await _notifications.show(
      99,
      '🕌 Test Prayer Notification',
      'اذان کی آواز — یہ ایک ٹیسٹ ہے',
      NotificationDetails(android: details),
      payload: 'test',
    );
  }

  // ─── Schedule all enabled prayer notifications ────────────────────────────
  static Future<void> scheduleAllPrayers({
    required Position position,
    required String madhab,
  }) async {
    await initialize();
    await cancelAllNotifications();

    final params = await _buildParams();
    final toggles = await SavedPrefernces.getAllPrayerNotificationToggles();
    final globalEnabled = await SavedPrefernces.getPrayerNotificationsEnabled();

    if (!globalEnabled) return;

    final now = DateTime.now();
    final coordinates = Coordinates(position.latitude, position.longitude);

    // 1. Get Timezone and set it as local
    String tzName =
        tz_lookup.latLngToTimezoneString(position.latitude, position.longitude);
    try {
      tz.setLocalLocation(tz.getLocation(tzName));
    } catch (_) {
      // Fallback if zone not found
    }

    // 2. Schedule for today and tomorrow to cover the next 24 hours
    List<DateTime> days = [
      now,
      now.add(const Duration(days: 1)),
    ];

    for (DateTime day in days) {
      final PrayerTimes pt = PrayerTimes(
        coordinates: coordinates,
        date: day,
        calculationParameters: params,
        precision: true,
      );

      final Map<String, DateTime?> times = {
        'fajr': pt.fajr,
        'zuhr': pt.dhuhr,
        'asr': pt.asr,
        'maghrib': pt.maghrib,
        'isha': pt.isha,
      };

      for (final entry in times.entries) {
        if (toggles[entry.key] == true && entry.value != null) {
          // Unique ID for tomorrow's notifications to avoid overwriting today's
          // Today: 1-5, Tomorrow: 11-15 (or similar offset)
          int dayOffset = (day == days[0]) ? 0 : 10;
          await _scheduleNotification(
            id: prayerNotifIds[entry.key]! + dayOffset,
            prayerKey: entry.key,
            prayerTime: entry.value!,
          );
        }
      }
    }
  }

  // ─── Schedule a single prayer ────────────────────────────────────────────
  static Future<void> _scheduleNotification({
    required int id,
    required String prayerKey,
    required DateTime prayerTime,
  }) async {
    // prayerTime is UTC from adhan_dart
    if (prayerTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime scheduled = tz.TZDateTime.from(prayerTime, tz.local);
    final displayName = prayerDisplayNames[prayerKey] ?? prayerKey;
    final details = await _androidDetails(displayName);

    await _notifications.zonedSchedule(
      id,
      '🕌 $displayName نماز کا وقت',
      'وقت نماز $displayName آ گیا۔ اللہ آپ کی نماز قبول فرمائے۔',
      scheduled,
      NotificationDetails(android: details),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: prayerKey,
    );
  }

  // ─── Cancel helpers ─────────────────────────────────────────────────────
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelPrayerNotification(String prayerKey) async {
    final id = prayerNotifIds[prayerKey];
    if (id != null) await _notifications.cancel(id);
  }

  // ─── Reschedule for tomorrow (called from background) ────────────────────
  static Future<void> rescheduleForTomorrow({
    required Position position,
    required String madhab,
  }) async {
    await scheduleAllPrayers(position: position, madhab: madhab);
  }

  static Future<List<PendingNotificationRequest>> getPendingNotifications() =>
      _notifications.pendingNotificationRequests();
}
