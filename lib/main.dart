import 'dart:developer';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/form_validate.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/material_screen.dart';
import 'package:provider/provider.dart';
import 'Helper/tasbih_helper.dart';
import 'Provider/main_provider.dart';
import 'Provider/quran_data_provider.dart';
import 'Provider/audio_provider.dart';
import 'Provider/prayer_provider.dart';
import 'Services/analytics_service.dart';
import 'Services/prayer_notification_service.dart';
import 'Services/quran_audio_handler.dart';
import 'Services/recitation_downloads.dart';
import 'features/hajj_live/hajj_live_module.dart';

late ObjectBox objectbox;
late QuranAudioHandler audioHandler;

/// Connects recitation to the system media session (notification, lock
/// screen, headset and Bluetooth controls). Falls back to in-app playback
/// only if the platform service cannot start.
Future<QuranAudioHandler> _initAudioHandler() async {
  try {
    return await AudioService.init(
      builder: () => QuranAudioHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId:
            'com.devsinntechnologies.iqraquran.recitation',
        androidNotificationChannelName: 'Quran Recitation',
        androidNotificationChannelDescription:
            'Playback controls for Quran recitation',
        androidNotificationIcon: 'drawable/ic_stat_recitation',
        notificationColor: Color(0xff227C9E),
        // Leaves the foreground on pause so a paused notification can be
        // swiped away and stop() can remove it. Resuming from the
        // notification, lock screen or a headset is still allowed on
        // Android 12+ because media controls are exempt from the
        // background-start limits.
        androidStopForegroundOnPause: true,
        androidNotificationClickStartsActivity: true,
        androidResumeOnClick: true,
      ),
    );
  } catch (e) {
    log('Media session unavailable, using in-app playback only: $e');
    return QuranAudioHandler();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AnalyticsService.initialize();

  // Initialize notification service early to request permissions on first launch
  await PrayerNotificationService.initialize();

  objectbox = await ObjectBox.init();
  audioHandler = await _initAudioHandler();
  await RecitationDownloads.instance.init();
  // await getCustomTheme();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // GeneratedRoutes _appRoutes = GeneratedRoutes();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyProvider()),
        ChangeNotifierProvider(create: ((context) => TasbeeCount())),
        ChangeNotifierProvider(create: ((context) => FormValidate())),
        ChangeNotifierProvider(create: ((context) => ThemeProvider())),
        ChangeNotifierProvider(create: ((context) => TasbeehProvider())),
        ChangeNotifierProvider(create: (context) => AudioProvider(audioHandler)),
        ChangeNotifierProvider.value(value: RecitationDownloads.instance),
        ChangeNotifierProvider(create: (context) => PrayerProvider()),
        ChangeNotifierProvider(create: ((context) => QuranDataProvider())),
        ChangeNotifierProvider(create: (_) => HajjLiveProvider()),
      ],
      // child: const Demo(),
      child: const MaterialScreen(),
    );
  }
}
