import 'dart:async';
import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../../../../Provider/theme_provider.dart';
import 'flutter_qiblah.dart';

class QiblaMessageView extends StatelessWidget {
  const QiblaMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.primaryLabel,
    this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: color.withValues(alpha: 0.55)),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
                height: 1.45,
                color: Colors.grey[700],
              ),
            ),
            if (primaryLabel != null && onPrimary != null) ...[
              const SizedBox(height: 22),
              ElevatedButton(
                onPressed: onPrimary,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: const StadiumBorder(),
                ),
                child: Text(primaryLabel!),
              ),
            ],
            if (secondaryLabel != null && onSecondary != null) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: onSecondary,
                child: Text(secondaryLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class QiblahCompass extends StatefulWidget {
  const QiblahCompass({super.key});

  @override
  State<QiblahCompass> createState() => _QiblahCompassState();
}

class _QiblahCompassState extends State<QiblahCompass> {
  final _locationStreamController =
      StreamController<LocationStatus>.broadcast();

  Stream<LocationStatus> get stream => _locationStreamController.stream;

  @override
  void initState() {
    super.initState();
    _checkLocationStatus();
  }

  @override
  void dispose() {
    _locationStreamController.close();
    super.dispose();
  }

  Future<void> _checkLocationStatus() async {
    try {
      var locationStatus = await FlutterQiblah.checkLocationStatus();

      if (!locationStatus.enabled) {
        if (!_locationStreamController.isClosed) {
          _locationStreamController.add(locationStatus);
        }
        return;
      }

      if (locationStatus.status == LocationPermission.denied) {
        await FlutterQiblah.requestPermissions();
        locationStatus = await FlutterQiblah.checkLocationStatus();
      }

      if (!_locationStreamController.isClosed) {
        _locationStreamController.add(locationStatus);
      }
    } catch (e) {
      if (!_locationStreamController.isClosed) {
        _locationStreamController.addError(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    return Container(
      alignment: Alignment.center,
      color: themeProvider.selectedSecondary,
      child: StreamBuilder<LocationStatus>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: themeProvider.selectedTheme),
                  const SizedBox(height: 14),
                  const Text('Checking location…'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return QiblaMessageView(
              icon: Icons.location_off_rounded,
              title: 'Location error',
              message: snapshot.error.toString(),
              color: themeProvider.selectedTheme,
              primaryLabel: 'Retry',
              onPrimary: _checkLocationStatus,
            );
          }

          final status = snapshot.data;
          if (status == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!status.enabled) {
            return QiblaMessageView(
              icon: Icons.gps_off_rounded,
              title: 'Location is turned off',
              message:
                  'Turn on GPS / Location services so we can calculate Qibla from your position.',
              color: themeProvider.selectedTheme,
              primaryLabel: 'Open location settings',
              onPrimary: () async {
                await FlutterQiblah.openLocationSettings();
                await _checkLocationStatus();
              },
              secondaryLabel: 'Retry',
              onSecondary: _checkLocationStatus,
            );
          }

          switch (status.status) {
            case LocationPermission.always:
            case LocationPermission.whileInUse:
              return const QiblahCompassWidget();
            case LocationPermission.denied:
              return QiblaMessageView(
                icon: Icons.location_disabled_rounded,
                title: 'Location permission needed',
                message:
                    'Allow location access to show the correct Qibla direction for your area.',
                color: themeProvider.selectedTheme,
                primaryLabel: 'Allow location',
                onPrimary: _checkLocationStatus,
              );
            case LocationPermission.deniedForever:
              return QiblaMessageView(
                icon: Icons.lock_outline_rounded,
                title: 'Permission permanently denied',
                message:
                    'Location permission is blocked. Open app settings and enable Location for IQRA QURAN.',
                color: themeProvider.selectedTheme,
                primaryLabel: 'Open app settings',
                onPrimary: () async {
                  await FlutterQiblah.openAppSettings();
                  await _checkLocationStatus();
                },
              );
            default:
              return QiblaMessageView(
                icon: Icons.location_searching_rounded,
                title: 'Enable location permission',
                message: 'Location access is required for Qibla.',
                color: themeProvider.selectedTheme,
                primaryLabel: 'Retry',
                onPrimary: _checkLocationStatus,
              );
          }
        },
      ),
    );
  }
}

/// Live compass — listens to [FlutterCompass.events] directly every frame.
class QiblahCompassWidget extends StatefulWidget {
  const QiblahCompassWidget({super.key});

  @override
  State<QiblahCompassWidget> createState() => _QiblahCompassWidgetState();
}

class _QiblahCompassWidgetState extends State<QiblahCompassWidget> {
  Position? _position;
  String? _positionError;
  bool _loadingPosition = true;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _loadPosition() async {
    setState(() {
      _loadingPosition = true;
      _positionError = null;
    });

    final pos = await FlutterQiblah.resolvePosition();
    if (!mounted) return;

    if (pos == null) {
      setState(() {
        _loadingPosition = false;
        _positionError =
            'Could not get your location. Enable GPS and try again.';
      });
      return;
    }

    setState(() {
      _position = pos;
      _loadingPosition = false;
    });

    // Keep refining location if user moves; compass heading updates separately.
    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 50,
      ),
    ).listen((p) {
      if (!mounted) return;
      setState(() => _position = p);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final size = MediaQuery.of(context).size;
    final compassSize = size.width * 0.85;

    if (_loadingPosition) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: themeProvider.selectedTheme),
            const SizedBox(height: 16),
            const Text('Getting your location…',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    if (_positionError != null || _position == null) {
      return QiblaMessageView(
        icon: Icons.location_off_rounded,
        title: 'Location needed',
        message: _positionError ?? 'Unknown location error',
        color: themeProvider.selectedTheme,
        primaryLabel: 'Retry',
        onPrimary: _loadPosition,
      );
    }

    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      return QiblaMessageView(
        icon: Icons.compass_calibration_outlined,
        title: 'Compass not available',
        message:
            'This device does not expose a compass sensor. Live Qibla cannot run here.',
        color: themeProvider.selectedTheme,
        primaryLabel: 'Go back',
        onPrimary: () => Navigator.pop(context),
      );
    }

    final position = _position!;

    return Container(
      height: size.height,
      width: size.width,
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/BgImage.png'),
          fit: BoxFit.cover,
        ),
        color: Colors.grey[100],
      ),
      child: StreamBuilder<CompassEvent>(
        stream: compassStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return QiblaMessageView(
              icon: Icons.error_outline_rounded,
              title: 'Compass error',
              message: snapshot.error.toString(),
              color: themeProvider.selectedTheme,
              primaryLabel: 'Go back',
              onPrimary: () => Navigator.pop(context),
            );
          }

          final heading = snapshot.data?.heading;
          if (heading == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: themeProvider.selectedTheme),
                  const SizedBox(height: 16),
                  const Text(
                    'Waiting for compass…',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Hold phone flat and move it in a figure‑8',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            );
          }

          final direction = FlutterQiblah.buildDirection(
            heading: heading,
            position: position,
            accuracy: snapshot.data?.accuracy,
          );

          final turn = direction.degreesToQibla;
          final turnAbs = turn.abs().toStringAsFixed(0);
          final turnLabel = direction.isFacingQibla
              ? 'Facing Qibla'
              : (turn > 0
                  ? 'Turn right $turnAbs°'
                  : 'Turn left $turnAbs°');

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Align your phone flat',
                style: TextStyle(
                  color: themeProvider.selectedTheme.withValues(alpha: 0.75),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (direction.needsCalibration) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.sync_problem_rounded,
                            color: Colors.orange, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Compass needs calibration. Move your phone in a figure‑8 away from metal.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: Color(0xFF8A5A00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: compassSize,
                height: compassSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotate so the Kaaba needle points toward Qibla relative to phone.
                    Transform.rotate(
                      angle: direction.qiblah * (pi / 180) * -1,
                      alignment: Alignment.center,
                      child: Image.asset(
                        'assets/images/qiblaFinal.png',
                        fit: BoxFit.cover,
                        width: compassSize * 0.85,
                        height: compassSize * 0.85,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: direction.isFacingQibla
                            ? Colors.green
                            : themeProvider.selectedTheme,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                decoration: BoxDecoration(
                  color: themeProvider.selectedSecondary,
                  borderRadius: BorderRadius.circular(40),
                  border: direction.isFacingQibla
                      ? Border.all(color: Colors.green, width: 2)
                      : null,
                ),
                child: Column(
                  children: [
                    Text(
                      turnLabel,
                      style: TextStyle(
                        color: direction.isFacingQibla
                            ? Colors.green.shade700
                            : themeProvider.selectedTheme,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Heading ${direction.direction.toStringAsFixed(0)}°  •  Qibla ${direction.offset.toStringAsFixed(0)}°',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
