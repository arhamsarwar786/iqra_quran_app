// import "package:flutter_local_notifications/flutter_local_notifications.dart";
// import 'package:timezone/timezone.dart' as tz;

// class Notify {
//   static final _notifiction = FlutterLocalNotificationsPlugin();
//   static init() {
//     final AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings("@mipmap/ic_launcher");
//     final InitializationSettings initializationSettings =
//         InitializationSettings(
//       android: initializationSettingsAndroid,
//     );
//     _notifiction.initialize(initializationSettings);
//   }

//   static Future<void> showNotification({
//     var id = 0,
//     var title,
//     var body,
//     var payload,
//   }) async =>
//       _notifiction.show(id, title, body, await notificationDetails());
//   static showScheduleNotification({
//     var id = 0,
//     var title,
//     var body,
//     var payload,
//     DateTime? schdeuleTime,
//   }) =>
//       _notifiction.zonedSchedule(
//           id,
//           title,
//           body,
//           // tz.TZDateTime.from(schdeuleTime!, tz.UTC),
//           tz.TZDateTime.now(tz.local).add(const Duration(seconds: 5)),
//           notificationDetails(),
//           payload: payload,
//           uiLocalNotificationDateInterpretation:
//               UILocalNotificationDateInterpretation.absoluteTime,
//           androidAllowWhileIdle: true);
//   static NotificationDetails notificationDetails() {
//     return const NotificationDetails(
//       android: AndroidNotificationDetails(
//         'repeating channel id 8',
//         'repeating channel name',
//         channelDescription: 'repeating discription',
//         importance: Importance.max,
//         // sound:RawResourceAndroidNotificationSound("res_azanf.mp3"),
//         // playSound: true
//       ),
//     );
//   }
// }
