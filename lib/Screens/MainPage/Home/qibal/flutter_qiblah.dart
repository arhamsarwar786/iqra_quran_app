import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';

import 'utils.dart';
import '../../../../Helper/preference/saved_preferences.dart';

enum CompassSupportStatus {
  checking,
  supported,
  unsupported,
  needsCalibration,
  unknownError,
}

class LocationStatus {
  final bool enabled;
  final LocationPermission status;

  const LocationStatus(this.enabled, this.status);
}

class QiblahDirection {
  final double qiblah;
  final double direction;
  final double offset;
  final double? accuracy;
  final double? latitude;
  final double? longitude;

  const QiblahDirection({
    required this.qiblah,
    required this.direction,
    required this.offset,
    this.accuracy,
    this.latitude,
    this.longitude,
  });

  /// Degrees to turn (shortest path). 0 = facing Qibla.
  double get degreesToQibla {
    var diff = offset - direction;
    while (diff > 180) {
      diff -= 360;
    }
    while (diff < -180) {
      diff += 360;
    }
    return diff;
  }

  bool get isFacingQibla => degreesToQibla.abs() < 8;

  bool get needsCalibration {
    final a = accuracy;
    if (a == null) return false;
    if (a <= 1) return true;
    if (!Platform.isAndroid && a >= 25) return true;
    return false;
  }
}

enum QiblahErrorType {
  compassUnsupported,
  compassError,
  locationError,
}

class QiblahError implements Exception {
  final QiblahErrorType type;
  final String message;

  const QiblahError(this.type, this.message);

  @override
  String toString() => message;
}

/// Helpers for Qibla (no long-lived singleton stream — UI listens to sensors directly).
class FlutterQiblah {
  FlutterQiblah._();

  /// Lightweight check — does not keep a long subscription that can break the EventChannel.
  static Future<CompassSupportStatus> checkCompassSupport() async {
    try {
      if (FlutterCompass.events == null) {
        return CompassSupportStatus.unsupported;
      }

      // Peek one event with a short timeout, then cancel immediately.
      final completer = Completer<CompassSupportStatus>();
      StreamSubscription<CompassEvent>? sub;
      Timer? timer;

      timer = Timer(const Duration(seconds: 3), () {
        sub?.cancel();
        if (!completer.isCompleted) {
          completer.complete(CompassSupportStatus.unsupported);
        }
      });

      sub = FlutterCompass.events!.listen(
        (event) {
          if (event.heading == null) return;
          timer?.cancel();
          sub?.cancel();
          if (completer.isCompleted) return;

          final accuracy = event.accuracy;
          if (accuracy != null && Platform.isAndroid && accuracy <= 0) {
            completer.complete(CompassSupportStatus.needsCalibration);
          } else {
            completer.complete(CompassSupportStatus.supported);
          }
        },
        onError: (_) {
          timer?.cancel();
          sub?.cancel();
          if (!completer.isCompleted) {
            completer.complete(CompassSupportStatus.unknownError);
          }
        },
        cancelOnError: true,
      );

      return completer.future;
    } catch (_) {
      return CompassSupportStatus.unknownError;
    }
  }

  static Future<LocationPermission> requestPermissions() =>
      Geolocator.requestPermission();

  static Future<LocationStatus> checkLocationStatus() async {
    final status = await Geolocator.checkPermission();
    final enabled = await Geolocator.isLocationServiceEnabled();
    return LocationStatus(enabled, status);
  }

  static Future<bool> openLocationSettings() =>
      Geolocator.openLocationSettings();

  static Future<bool> openAppSettings() => Geolocator.openAppSettings();

  static Future<Position?> resolvePosition() async {
    final savedLat = await SavedPrefernces.getLat();
    final savedLng = await SavedPrefernces.getLng();
    Position? best;

    if (savedLat != 0.0 && savedLng != 0.0) {
      best = _createPosition(savedLat, savedLng);
    }

    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) best = lastKnown;
    } catch (_) {}

    try {
      final current = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      best = current;
      await SavedPrefernces.setLat(current.latitude);
      await SavedPrefernces.setLng(current.longitude);
    } catch (_) {}

    return best;
  }

  static QiblahDirection buildDirection({
    required double heading,
    required Position position,
    double? accuracy,
  }) {
    final h = _normalize(heading);
    final offset =
        Utils.getOffsetFromNorth(position.latitude, position.longitude);
    // Same formula as classic flutter_qiblah: needle rotation uses -qiblah.
    final qiblah = _normalize(h + (360 - offset));
    return QiblahDirection(
      qiblah: qiblah,
      direction: h,
      offset: offset,
      accuracy: accuracy,
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  static double _normalize(double value) {
    var v = value % 360;
    if (v < 0) v += 360;
    return v;
  }

  static Position _createPosition(double lat, double lng) {
    return Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }

  /// No-op kept for old call sites.
  Future<void> dispose() async {}
}

double shortestAngleDelta(double fromDeg, double toDeg) {
  var delta = (toDeg - fromDeg) % 360;
  if (delta > 180) delta -= 360;
  if (delta < -180) delta += 360;
  return delta;
}

double degToRad(double deg) => deg * math.pi / 180;
