import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'utils.dart';
import 'package:geolocator/geolocator.dart';
import 'package:stream_transform/stream_transform.dart' show CombineLatest;
import '../../../../Helper/preference/saved_preferences.dart';

/// [FlutterQiblah] is a singleton class that provides access to compass events,
/// check for sensor support, get current location, and calculate Qiblah direction.
class FlutterQiblah {
  static const MethodChannel _channel = MethodChannel('ml.medyas.flutter_qiblah');
  static final FlutterQiblah _instance = FlutterQiblah._();

  Stream<QiblahDirection>? _qiblahStream;

  FlutterQiblah._();

  factory FlutterQiblah() {
    return _instance;
  }

  /// Check device sensor support
  static Future<bool> androidDeviceSensorSupport() async {
    if (Platform.isAndroid) {
      try {
        // If the custom plugin was intended to be used, try it
        final support = await _channel.invokeMethod("androidSupportSensor");
        return support ?? true;
      } catch (e) {
        // If plugin is missing or error, fallback to assuming true 
        // and handle specific sensor status in the compass stream check.
        return true; 
      }
    }
    // iOS usually has better compass support out of the box
    return true; 
  }

  /// Request Location permission
  static Future<LocationPermission> requestPermissions() async {
    return await Geolocator.requestPermission();
  }

  /// get location status: GPS enabled and permission status
  static Future<LocationStatus> checkLocationStatus() async {
    final status = await Geolocator.checkPermission();
    final enabled = await Geolocator.isLocationServiceEnabled();
    return LocationStatus(enabled, status);
  }

  /// Provides a stream of Qiblah direction, merging compass and location updates.
  static Stream<QiblahDirection> get qiblahStream {
    if (FlutterCompass.events == null) {
      return Stream.error("Compass not supported on this device");
    }

    // Reuse stream if exists, or build a new one
    _instance._qiblahStream ??= _buildQiblahStream();
    return _instance._qiblahStream!;
  }

  static Stream<QiblahDirection> _buildQiblahStream() {
    final compassStream = FlutterCompass.events;
    if (compassStream == null) {
      return Stream.error("Compass not supported on this device");
    }

    // Use a more reliable position source that provides immediate value if possible
    final positionStream = _getReliablePositionStream();

    return compassStream.combineLatest<Position, QiblahDirection>(
      positionStream,
      (event, position) {
        // Calculate the Qiblah offset to North
        final offSet = Utils.getOffsetFromNorth(position.latitude, position.longitude);

        // Adjust Qiblah direction based on North direction (heading)
        // If event.heading is null, it means sensor data is temporarily unavailable
        final qiblah = (event.heading ?? 0.0) + (360 - offSet);

        return QiblahDirection(qiblah, event.heading ?? 0.0, offSet);
      },
    );
  }

  /// Creates a position stream that emits cached/last known position first
  static Stream<Position> _getReliablePositionStream() async* {
    // 1. Try our saved preferences first (fastest)
    final savedLat = await SavedPrefernces.getLat();
    final savedLng = await SavedPrefernces.getLng();
    if (savedLat != 0.0 && savedLng != 0.0) {
      yield _createPosition(savedLat, savedLng);
    }

    // 2. Try last known position for quick update
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        yield lastKnown;
      }
    } catch (_) {}

    // 3. Get current position once for accuracy
    try {
      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
      yield current;
      
      // Update saved preferences with latest accurate position
      await SavedPrefernces.setLat(current.latitude);
      await SavedPrefernces.setLng(current.longitude);
    } catch (_) {}

    // 4. Then follow the stream for any significant changes
    yield* Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        distanceFilter: 200, // Update only if user moves 200 meters
      ),
    );
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

  Future<void> dispose() async {
    _qiblahStream = null;
  }
}

/// Location Status class
class LocationStatus {
  final bool enabled;
  final LocationPermission status;

  const LocationStatus(this.enabled, this.status);
}

/// Containing Qiblah, Direction and offset
class QiblahDirection {
  final double qiblah;
  final double direction;
  final double offset;

  const QiblahDirection(this.qiblah, this.direction, this.offset);
}

