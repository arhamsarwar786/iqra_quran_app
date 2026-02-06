import 'dart:async';
import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../Provider/theme_provider.dart';
import 'flutter_qiblah.dart';
import 'package:geolocator/geolocator.dart';

class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  _QiblahCompassState createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  get stream => _locationStreamController.stream;

  @override
  void initState() {
    _checkLocationStatus();
    super.initState();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    FlutterQiblah().dispose();
    super.dispose();
  }

  Future<void> _checkLocationStatus() async {
    final locationStatus = await FlutterQiblah.checkLocationStatus();
    if (locationStatus.enabled &&
        locationStatus.status == LocationPermission.denied) {
      await FlutterQiblah.requestPermissions();
      final s = await FlutterQiblah.checkLocationStatus();
      _locationStreamController.sink.add(s);
    } else {
      _locationStreamController.sink.add(locationStatus);
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      alignment: Alignment.center,
      color: themeProvider.selectedSecondary,
      child: StreamBuilder(
        stream: stream,
        builder: (context, AsyncSnapshot<LocationStatus> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData && snapshot.data!.enabled == true) {
            switch (snapshot.data!.status) {
              case LocationPermission.always:
              case LocationPermission.whileInUse:
                return const QiblahCompassWidget();
              case LocationPermission.denied:
                return _buildError(
                    themeProvider, "Location permission denied", true);
              case LocationPermission.deniedForever:
                return _buildError(themeProvider,
                    "Location permission permanently denied", false);
              default:
                return _buildError(
                    themeProvider, "Enable Location Permission", true);
            }
          } else {
            return _buildError(
                themeProvider, "Please enable Location services", true);
          }
        },
      ),
    );
  }

  Widget _buildError(ThemeProvider tp, String error, bool canRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_off_rounded,
              size: 64, color: tp.selectedTheme.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(error,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          if (canRetry) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkLocationStatus,
              style:
                  ElevatedButton.styleFrom(backgroundColor: tp.selectedTheme),
              child: const Text("Retry", style: TextStyle(color: Colors.white)),
            )
          ]
        ],
      ),
    );
  }
}

class QiblahCompassWidget extends StatelessWidget {
  const QiblahCompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);
    final size = MediaQuery.of(context).size;
    final compassSize = size.width * 0.85;

    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (_, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
              child: Text("Sensor Error: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red)));
        }

        if (!snapshot.hasData) {
          return const Center(child: Text("Waiting for sensor data..."));
        }

        final qiblahDirection = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Align your phone correctly",
              style: TextStyle(
                color: themeProvider.selectedTheme.withOpacity(0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 50),

            // Compass Stack
            SizedBox(
              width: compassSize,
              height: compassSize,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  // 1. Static Shadow/Background Ring
                  Container(
                    width: compassSize * 0.95,
                    height: compassSize * 0.95,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),

                  // 2. Compass Dial (Rotates with phone heading to keep North up)
                  Transform.rotate(
                    angle: (qiblahDirection.direction * (pi / 180) * -1),
                    child: Image.asset(
                      "assets/images/qibalcompass.png",
                      width: compassSize,
                      height: compassSize,
                    ),
                  ),

                  // 3. Qibla Needle/Kaaba (Points directly to Qibla)
                  Transform.rotate(
                    angle: (qiblahDirection.qiblah * (pi / 180) * -1),
                    alignment: Alignment.center,
                    child: Image.asset(
                      "assets/images/qiblaFinal.png",
                      width: compassSize * 0.65, // Adjusted to fit better
                      height: compassSize * 0.65,
                    ),
                  ),

                  // 4. Center Dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                        color: themeProvider.selectedTheme,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4)
                        ]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 70),

            // Info Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Column(
                children: [
                  Text(
                    "Qibla Offset",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${qiblahDirection.offset.toStringAsFixed(1)}° From North",
                    style: TextStyle(
                      color: themeProvider.selectedTheme,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
