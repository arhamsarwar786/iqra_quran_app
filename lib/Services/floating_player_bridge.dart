import 'dart:developer';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Provider/audio_provider.dart';
import '../Provider/quran_data_provider.dart';
import '../Provider/theme_provider.dart';

/// Connects the recitation to the native floating logo that stays over other
/// apps while Iqra is in the background (Android only).
///
/// The native side draws the logo and its controls; this sends it what is
/// being recited and runs the commands it sends back.
class FloatingPlayerBridge {
  static const MethodChannel _channel = MethodChannel('iqra/floating_player');
  static const String _enabledKey = 'float_over_apps';
  static const String _suggestedKey = 'float_over_apps_suggested';

  /// Whether the listener wants the logo over other apps. It also needs the
  /// "Display over other apps" permission.
  static final ValueNotifier<bool> enabled = ValueNotifier(true);

  static AudioProvider? _audio;
  static QuranDataProvider? _quran;
  static ThemeProvider? _theme;
  static Map<String, Object?>? _lastSent;
  static bool _wasActive = false;
  static VoidCallback? _onFirstRecitation;

  static bool get isSupported => Platform.isAndroid;

  /// [onSuggest] is called once, the first time a recitation starts without
  /// the permission, to offer turning the floating logo on.
  static Future<void> attach({
    required AudioProvider audio,
    required QuranDataProvider quran,
    required ThemeProvider theme,
    VoidCallback? onSuggest,
  }) async {
    if (!isSupported) return;
    _audio = audio;
    _quran = quran;
    _theme = theme;
    _onFirstRecitation = onSuggest;
    _channel.setMethodCallHandler(_onCall);
    try {
      final prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool(_enabledKey) ?? true;
    } catch (_) {}
    await _invoke('setEnabled', enabled.value);
    audio.addListener(_push);
    theme.addListener(_push);
    _push();
  }

  static Future<void> setEnabled(bool value) async {
    enabled.value = value;
    await _invoke('setEnabled', value);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
  }

  static Future<bool> canDrawOverlays() async {
    if (!isSupported) return false;
    try {
      return await _channel.invokeMethod<bool>('canDrawOverlays') ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system page where "Display over other apps" is allowed.
  static Future<void> openPermissionSettings() =>
      _invoke('openPermissionSettings');

  static void _push() {
    final audio = _audio;
    final quran = _quran;
    final theme = _theme;
    if (audio == null || quran == null || theme == null) return;

    if (audio.isActive && !_wasActive) _maybeSuggest();
    _wasActive = audio.isActive;

    final payload = <String, Object?>{
      'active': audio.isActive,
      'title': audio.currentSurahName,
      'subtitle': audio.isActive ? audio.ayahSubtitle(quran) : '',
      'playing': audio.isPlaying,
      'hasNext': audio.hasNext,
      'color': theme.selectedTheme.value,
    };
    // AudioProvider notifies often; only real changes go to the native side.
    if (mapEquals(payload, _lastSent)) return;
    _lastSent = payload;
    _invoke('update', payload);
  }

  static Future<void> _maybeSuggest() async {
    final suggest = _onFirstRecitation;
    if (suggest == null || !enabled.value) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_suggestedKey) ?? false) return;
      if (await canDrawOverlays()) return;
      await prefs.setBool(_suggestedKey, true);
      suggest();
    } catch (_) {}
  }

  static Future<dynamic> _onCall(MethodCall call) async {
    final audio = _audio;
    if (call.method != 'command' || audio == null) return null;
    switch (call.arguments) {
      case 'previous':
        await audio.skipPrevious();
        break;
      case 'toggle':
        await audio.togglePlayback();
        break;
      case 'next':
        await audio.skipNext();
        break;
      case 'stop':
        await audio.stopPlayback();
        break;
    }
    return null;
  }

  static Future<void> _invoke(String method, [Object? arguments]) async {
    if (!isSupported) return;
    try {
      await _channel.invokeMethod<void>(method, arguments);
    } catch (e) {
      log('Floating player: $method failed: $e');
    }
  }
}
