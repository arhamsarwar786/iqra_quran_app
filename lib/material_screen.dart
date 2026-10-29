import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/splash_screen.dart';
import 'package:provider/provider.dart';

import 'Provider/theme_provider.dart';
import 'Provider/audio_provider.dart';
import 'Provider/quran_data_provider.dart';
import 'Services/floating_player_bridge.dart';
import 'Services/recitation_downloads.dart';
import 'Widgets/audio_controller_overlay.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {
  final GlobalKey<ScaffoldMessengerState> _messengerKey =
      GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<String>? _downloadMessages;

  @override
  void initState() {
    super.initState();
    // Download progress also shows in the notification; this tells listeners
    // already in the app when a download finishes or pauses.
    _downloadMessages = RecitationDownloads.instance.messages.listen((message) {
      _messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ));
    });
    FloatingPlayerBridge.attach(
      audio: context.read<AudioProvider>(),
      quran: context.read<QuranDataProvider>(),
      theme: context.read<ThemeProvider>(),
      onSuggest: _suggestFloatingLogo,
    );
  }

  // Offered once, the first time a recitation starts.
  void _suggestFloatingLogo() {
    _messengerKey.currentState?.showSnackBar(SnackBar(
      content: const Text(
          'Keep the IQRA logo floating over other apps when you leave IQRA?'),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 8),
      action: SnackBarAction(
        label: 'Allow',
        onPressed: FloatingPlayerBridge.openPermissionSettings,
      ),
    ));
  }

  @override
  void dispose() {
    _downloadMessages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryMaterialColor =
        ThemeProvider.createMaterialColor(themeProvider.selectedTheme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: themeProvider.selectedTheme,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: themeProvider.selectedSecondary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        scaffoldMessengerKey: _messengerKey,
        navigatorObservers: [MiniPlayerRouteObserver.instance],
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3:
              true, // Switched to Material 3 for better visuals with Poppins
          primarySwatch: primaryMaterialColor,
          primaryColor: themeProvider.selectedTheme,
          scaffoldBackgroundColor: themeProvider.selectedSecondary,
          canvasColor: themeProvider.selectedSecondary,
          highlightColor: themeProvider.selectedTheme.withOpacity(0.1),
          splashColor: themeProvider.selectedTheme.withOpacity(0.1),
          fontFamily: 'Poppins', // Using the bundled Poppins font
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: primaryMaterialColor,
          ).copyWith(
            primary: themeProvider.selectedTheme,
            secondary: themeProvider.selectedTheme,
            background: themeProvider.selectedSecondary,
            surface: themeProvider.selectedSecondary,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: themeProvider.selectedTheme,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.noScaling,
            ),
            child: QuranMiniPlayerHost(child: child!),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
