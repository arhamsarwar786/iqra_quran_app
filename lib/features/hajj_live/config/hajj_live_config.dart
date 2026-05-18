class HajjLiveConfig {
  static const String githubConfigUrl = 'https://raw.githubusercontent.com/arhamsarwar786/hajj-json-IQRA-QURAN/main/hajj_live.json';
  static const Duration fetchTimeout = Duration(seconds: 10);
  static const List<int> retryIntervalsSeconds = [5, 15, 30, 60, 120];
  static const int maxRetries = 5;
  
  static const String streamPlatform = 'youtube';
  static const String embedBaseUrl = 'https://www.youtube.com/embed/';
  
  // YouTube embed parameters to hide controls and branding
  static const String embedParams = '?autoplay=1&controls=0&modestbranding=1&rel=0&fs=0&disablekb=1&iv_load_policy=3&playsinline=1';
  
  static const Map<String, String> cacheBypassHeaders = {
    'Cache-Control': 'no-cache',
    'Pragma': 'no-cache',
  };
  
  static const Duration autoRefreshInterval = Duration(minutes: 5);

  // Localization strings
  static const String comingSoonTitle = "Hajj Live 1446";
  static const String comingSoonBody = "Hajj Live streaming will begin soon. Stay tuned for this blessed event. In sha Allah.";
  
  static const String streamConnecting = "Connecting to live stream...";
  static const String streamRetrying = "Reconnecting... (Attempt {n} of {max})";
  static const String streamNextRetry = "Next retry in {seconds} seconds";
  
  static const String errorTitle = "Stream Currently Unavailable";
  static const String errorBody = "We are experiencing technical difficulties connecting to the live stream. Our team has been notified.";
  
  static const String allFailedTitle = "Unable to Connect";
  static const String allFailedBody = "We were unable to connect to the live stream after several attempts. Please check your internet connection or try watching directly.";
  
  static const String streamEndedTitle = "JazakAllah Khair";
  static const String streamEndedBody = "The Hajj Live 1446 stream has concluded. May Allah accept the Hajj of all pilgrims.";
  
  static const String patienceMsg = "JazakAllah for your patience";
}
