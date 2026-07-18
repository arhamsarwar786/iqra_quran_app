import 'package:appmetrica_plugin/appmetrica_plugin.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static const String _apiKey = '1ecc6ee4-3f62-4e94-ae41-6b80bea13fa2';

  static Future<void> initialize() async {
    try {
      // Families Policy: never collect/transmit Android Advertising ID (AAID).
      await AppMetrica.activate(
        const AppMetricaConfig(
          _apiKey,
          advIdentifiersTracking: false,
          locationTracking: false,
        ),
      );
      await AppMetrica.setAdvIdentifiersTracking(false);
      debugPrint('AppMetrica initialized successfully (AAID disabled)');
    } catch (e) {
      debugPrint('Failed to initialize AppMetrica: $e');
    }
  }

  static Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    try {
      await AppMetrica.reportEvent(name);
      debugPrint('Analytics: Event "$name" logged with params: $parameters');
    } catch (e) {
      debugPrint('Analytics: Failed to log event "$name": $e');
    }
  }

  // Feature specific methods
  static void trackFeatureAccess(String featureName) {
    logEvent('feature_access', parameters: {'feature_name': featureName});
  }

  static void trackQuranOpen(int surahId, String surahName) {
    logEvent('quran_open', parameters: {
      'surah_id': surahId,
      'surah_name': surahName,
    });
  }

  static void trackSearch(String query) {
    logEvent('search', parameters: {'query': query});
  }

  static void trackPrayerTimeCheck() {
    logEvent('prayer_time_check');
  }

  static void trackSettingChange(String setting, dynamic value) {
    logEvent('setting_changed', parameters: {
      'setting': setting,
      'value': value.toString(),
    });
  }
}
