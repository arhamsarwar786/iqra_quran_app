import 'package:flutter/material.dart';
import 'package:iqra/Screens/MainPage/Home/qibal/flutter_qiblah.dart';
import 'package:provider/provider.dart';

import '../../../../Provider/theme_provider.dart';
import '../../../../Services/analytics_service.dart';
import '../../../../widgets.dart';
import 'compass.dart';

class DirectionTOQiblah extends StatefulWidget {
  const DirectionTOQiblah({super.key});

  @override
  State<DirectionTOQiblah> createState() => _DirectionTOQiblahState();
}

class _DirectionTOQiblahState extends State<DirectionTOQiblah> {
  late Future<CompassSupportStatus> _supportFuture;

  @override
  void initState() {
    super.initState();
    AnalyticsService.trackFeatureAccess('qibla');
    _supportFuture = FlutterQiblah.checkCompassSupport();
  }

  void _retrySupportCheck() {
    setState(() {
      _supportFuture = FlutterQiblah.checkCompassSupport();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return Scaffold(
      appBar: mainScreenAppBarPush(context, "Direction to Qiblah"),
      body: SafeArea(
        child: FutureBuilder<CompassSupportStatus>(
          future: _supportFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.selectedTheme),
                    const SizedBox(height: 16),
                    const Text(
                      'Checking compass sensor…',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.hasError) {
              return QiblaMessageView(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                message: snapshot.error.toString(),
                color: theme.selectedTheme,
                primaryLabel: 'Try again',
                onPrimary: _retrySupportCheck,
              );
            }

            switch (snapshot.data ?? CompassSupportStatus.unknownError) {
              case CompassSupportStatus.supported:
              case CompassSupportStatus.needsCalibration:
                return const QiblahCompass();
              case CompassSupportStatus.unsupported:
                return QiblaMessageView(
                  icon: Icons.compass_calibration_outlined,
                  title: 'Compass not supported',
                  message:
                      'This device does not have a working magnetometer / compass sensor, so live Qibla direction cannot be shown.\n\nTry another device, or use a map-based Qibla finder.',
                  color: theme.selectedTheme,
                  primaryLabel: 'Check again',
                  onPrimary: _retrySupportCheck,
                  secondaryLabel: 'Go back',
                  onSecondary: () => Navigator.pop(context),
                );
              case CompassSupportStatus.unknownError:
                return QiblaMessageView(
                  icon: Icons.sensors_off_rounded,
                  title: 'Could not read sensors',
                  message:
                      'We could not access the compass on this device. Close other apps using sensors, then try again.',
                  color: theme.selectedTheme,
                  primaryLabel: 'Try again',
                  onPrimary: _retrySupportCheck,
                );
              case CompassSupportStatus.checking:
                return Center(
                  child: CircularProgressIndicator(color: theme.selectedTheme),
                );
            }
          },
        ),
      ),
    );
  }
}
