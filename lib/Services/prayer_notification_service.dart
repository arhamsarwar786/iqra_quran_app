import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
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
        // University of Islamic Sciences, Karachi — standard for Pakistan
        // Fajr 18°, Isha 18°
        params = CalculationMethod.karachi();
        break;
      case 'mwl':
        params = CalculationMethod.muslimWorldLeague();
        break;
      case 'isna':
        params = CalculationMethod.northAmerica();
        break;
      case 'egypt':
        params = CalculationMethod.egyptian();
        break;
      default:
        params = CalculationMethod.karachi();
    }
    params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return params;
  }

  // ─── Returns the Android notification details ────────────────────────────
  static Future<AndroidNotificationDetails> _androidDetails(
      String prayerName) async {
    final customPath = await SavedPrefernces.getCustomAzanPath();

    // Use custom MP3 if the user picked one and the file still exists
    if (customPath != null && File(customPath).existsSync()) {
      return AndroidNotificationDetails(
        'prayer_custom_sound',
        'Prayer Times (Custom Sound)',
        channelDescription: 'Adhan notifications with your custom sound',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        sound: UriAndroidNotificationSound(customPath),
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'وقت نماز $prayerName آ گیا',
          contentTitle: '🕌 $prayerName — نماز کا وقت',
        ),
      );
    }

    // Default: bundled azan.wav in res/raw
    return AndroidNotificationDetails(
      'prayer_notifications',
      'Prayer Times',
      channelDescription: 'Adhan notifications for daily prayer times',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('azan'),
      enableVibration: true,
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

    final now = DateTime.now().toUtc();
    final coordinates = Coordinates(position.latitude, position.longitude);

    final PrayerTimes pt = PrayerTimes(
      coordinates: coordinates,
      date: now,
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
        await _scheduleNotification(
          id: prayerNotifIds[entry.key]!,
          prayerKey: entry.key,
          prayerTime: entry.value!,
        );
      }
    }
  }

  // ─── Schedule a single prayer ────────────────────────────────────────────
  static Future<void> _scheduleNotification({
    required int id,
    required String prayerKey,
    required DateTime prayerTime,
  }) async {
    final DateTime localTime = prayerTime.toLocal();
    if (localTime.isBefore(DateTime.now())) return;

    final tz.TZDateTime scheduled = tz.TZDateTime.from(localTime, tz.local);
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
