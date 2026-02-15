import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import '../Helper/preference/saved_preferences.dart';

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Notification IDs for each prayer
  static const int fajrId = 1;
  static const int zuhrId = 2;
  static const int asrId = 3;
  static const int maghribId = 4;
  static const int ishaId = 5;

  /// Initialize the notification service
  static Future<void> initialize() async {
    tz_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions for iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Request permissions for Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - can navigate to prayer screen
    print('Notification tapped: ${response.payload}');
  }

  /// Schedule all prayer notifications for the day
  static Future<void> scheduleAllPrayers({
    required Position position,
    required String madhab,
  }) async {
    try {
      // Cancel existing notifications first
      await cancelAllNotifications();

      // Get prayer times
      Coordinates coordinates =
          Coordinates(position.latitude, position.longitude);
      CalculationParameters params = CalculationMethod.muslimWorldLeague();
      params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

      final DateTime nowUtc = DateTime.now().toUtc();
      PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: nowUtc,
        calculationParameters: params,
        precision: true,
      );

      // Schedule each prayer
      await _schedulePrayerNotification(
        id: fajrId,
        prayerName: 'Fajr',
        prayerTime: prayerTimes.fajr,
      );

      await _schedulePrayerNotification(
        id: zuhrId,
        prayerName: 'Zuhr',
        prayerTime: prayerTimes.dhuhr,
      );

      await _schedulePrayerNotification(
        id: asrId,
        prayerName: 'Asr',
        prayerTime: prayerTimes.asr,
      );

      await _schedulePrayerNotification(
        id: maghribId,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes.maghrib,
      );

      await _schedulePrayerNotification(
        id: ishaId,
        prayerName: 'Isha',
        prayerTime: prayerTimes.isha,
      );

      print('All prayer notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling prayer notifications: $e');
    }
  }

  /// Schedule a single prayer notification
  static Future<void> _schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime? prayerTime,
  }) async {
    if (prayerTime == null) return;

    final DateTime localTime = prayerTime.toLocal();
    final DateTime now = DateTime.now();

    // Only schedule if the prayer time is in the future
    if (localTime.isAfter(now)) {
      final tz.TZDateTime scheduledTime =
          tz.TZDateTime.from(localTime, tz.local);

      await _notifications.zonedSchedule(
        id,
        'Prayer Time: $prayerName',
        'It\'s time for $prayerName prayer. May Allah accept your prayers.',
        scheduledTime,
        _notificationDetails(prayerName),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
      );

      print('Scheduled $prayerName notification for $localTime');
    }
  }

  /// Get notification details with custom sound and styling
  static NotificationDetails _notificationDetails(String prayerName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        'prayer_notifications',
        'Prayer Times',
        channelDescription: 'Notifications for daily prayer times',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(
          'It\'s time for $prayerName prayer. May Allah accept your prayers.',
          contentTitle: 'Prayer Time: $prayerName',
        ),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
      ),
    );
  }

  /// Cancel all scheduled notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
    print('All prayer notifications cancelled');
  }

  /// Cancel a specific prayer notification
  static Future<void> cancelPrayerNotification(int id) async {
    await _notifications.cancel(id);
    print('Cancelled notification with id: $id');
  }

  /// Get pending notifications (for debugging)
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  /// Check if notifications are enabled
  static Future<bool> areNotificationsEnabled() async {
    final bool? enabled = await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return enabled ?? false;
  }

  /// Reschedule notifications for tomorrow
  static Future<void> rescheduleForTomorrow({
    required Position position,
    required String madhab,
  }) async {
    try {
      await cancelAllNotifications();

      // Get tomorrow's prayer times
      Coordinates coordinates =
          Coordinates(position.latitude, position.longitude);
      CalculationParameters params = CalculationMethod.muslimWorldLeague();
      params.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

      final DateTime tomorrowUtc =
          DateTime.now().toUtc().add(const Duration(days: 1));
      PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: tomorrowUtc,
        calculationParameters: params,
        precision: true,
      );

      // Schedule each prayer
      await _schedulePrayerNotification(
        id: fajrId,
        prayerName: 'Fajr',
        prayerTime: prayerTimes.fajr,
      );

      await _schedulePrayerNotification(
        id: zuhrId,
        prayerName: 'Zuhr',
        prayerTime: prayerTimes.dhuhr,
      );

      await _schedulePrayerNotification(
        id: asrId,
        prayerName: 'Asr',
        prayerTime: prayerTimes.asr,
      );

      await _schedulePrayerNotification(
        id: maghribId,
        prayerName: 'Maghrib',
        prayerTime: prayerTimes.maghrib,
      );

      await _schedulePrayerNotification(
        id: ishaId,
        prayerName: 'Isha',
        prayerTime: prayerTimes.isha,
      );

      print('Tomorrow\'s prayer notifications scheduled successfully');
    } catch (e) {
      print('Error scheduling tomorrow\'s notifications: $e');
    }
  }
}
