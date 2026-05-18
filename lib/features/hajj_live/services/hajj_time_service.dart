import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class HajjTimeService {
  static final HajjTimeService _instance = HajjTimeService._internal();
  factory HajjTimeService() => _instance;
  HajjTimeService._internal();

  bool _isInitialized = false;

  // Official Hajj 2026 Start Time (KSA Timezone)
  // Estimated: 8 Dhu al-Hijjah 1447 -> May 24, 2026, 05:00 AM
  final DateTime _hajjStartTimeKsa = DateTime(2026, 5, 24, 5, 0);

  Future<void> initialize() async {
    if (_isInitialized) return;
    tz.initializeTimeZones();
    _isInitialized = true;
  }

  /// Calculates the remaining duration until Hajj starts, 
  /// taking into account the user's local timezone vs KSA timezone.
  Duration getRemainingTime() {
    final nowLocal = DateTime.now();
    
    // Hajj start time in KSA (UTC+3)
    // To get the UTC time of the start: StartTime - 3 hours
    final hajjStartUtc = _hajjStartTimeKsa.subtract(const Duration(hours: 3));
    
    // Current time in UTC
    final nowUtc = nowLocal.toUtc();
    
    final difference = hajjStartUtc.difference(nowUtc);
    
    return difference.isNegative ? Duration.zero : difference;
  }

  /// Returns true if the current time is past the Hajj start time
  bool isHajjLiveStarted() {
    return getRemainingTime() == Duration.zero;
  }

  /// Formats duration into 00d : 00h : 00m : 00s
  String formatCountdown(Duration duration) {
    if (duration == Duration.zero) return "00d : 00h : 00m : 00s";
    
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    
    final days = twoDigits(duration.inDays);
    final hours = twoDigits(duration.inHours.remainder(24));
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    return "$days" "d : $hours" "h : $minutes" "m : $seconds" "s";
  }
}
