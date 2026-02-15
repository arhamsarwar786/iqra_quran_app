import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart' as tzmap;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../../../../Provider/theme_provider.dart';
import '../../../../widgets.dart';
import '../../../../Utils/share_verse.dart';
import '../../../../Helper/preference/saved_preferences.dart';
import '../qibal/qibla.dart';

class PrayerTime extends StatefulWidget {
  const PrayerTime({Key? key}) : super(key: key);

  @override
  State<PrayerTime> createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTime> {
  Timer? _timer;
  late Future<Map<String, dynamic>> _prayerCacheFuture;
  Map<String, dynamic>? _lastData;
  bool _showFardOnly = true;
  String _madhab = 'hanafi';

  @override
  void initState() {
    super.initState();
    _initMadhab();
    _prayerCacheFuture = _getPrayerData();
    // Update every second for the clock, calculations are light
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initMadhab() async {
    String m = await SavedPrefernces.getMadhab();
    if (mounted) {
      setState(() {
        _madhab = m;
        _refreshData();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _prayerCacheFuture = _getPrayerData();
    });
  }

  Future<Map<String, dynamic>> _getPrayerData() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw 'Location services are disabled.';

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied)
        throw 'Location permissions are denied';
    }

    if (permission == LocationPermission.deniedForever)
      throw 'Location permissions are permanently denied.';

    Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 15),
      );
    } catch (e) {
      position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low);
    }

    String locationName = "Searching...";
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        locationName =
            "${place.locality ?? place.subAdministrativeArea}, ${place.country}";
      }
    } catch (e) {
      locationName = "Location Detected";
    }

    // Calculation logic
    Coordinates coordinates =
        Coordinates(position.latitude, position.longitude);
    CalculationParameters params = CalculationMethod.muslimWorldLeague();
    params.madhab = _madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    // We pass TODAY'S DATE in UTC to ensure adhan_dart calculates correctly for the global day
    // then we handle local conversion manually.
    final DateTime nowUtc = DateTime.now().toUtc();
    PrayerTimes pt = PrayerTimes(
        coordinates: coordinates,
        date: nowUtc,
        calculationParameters: params,
        precision: true);

    DateTime tomorrowUtc = nowUtc.add(const Duration(days: 1));
    PrayerTimes ptTomorrow = PrayerTimes(
        coordinates: coordinates,
        date: tomorrowUtc,
        calculationParameters: params,
        precision: true);

    // Filtered lists
    final List<Map<String, dynamic>> timesList = [];
    final List<Map<String, dynamic>> fardList = [];

    void add(String name, DateTime? time, bool fard) {
      if (time == null) return;
      // Convert to local for specific device display and internal comparison
      final DateTime localTime = time.toLocal();
      final entry = {
        "name": name,
        "time": DateFormat("h:mm a").format(localTime),
        "dateTime": localTime,
        "isFard": fard,
      };
      timesList.add(entry);
      if (fard) fardList.add(entry);
    }

    // Add Farz
    add("Fajr", pt.fajr, true);
    add("Zuhr", pt.dhuhr, true);
    add("Asr", pt.asr, true);
    add("Maghrib", pt.maghrib, true);
    add("Isha", pt.isha, true);

    // Add Optionals
    DateTime? sunrise = pt.sunrise;
    add("Ishraq", sunrise?.add(const Duration(minutes: 15)), false);
    add("Chasht", sunrise?.add(const Duration(hours: 2, minutes: 15)), false);
    add("Awwabin", pt.maghrib?.add(const Duration(minutes: 15)), false);
    add("Witr", pt.isha?.add(const Duration(minutes: 30)), false);

    if (pt.maghrib != null && ptTomorrow.fajr != null) {
      Duration night = ptTomorrow.fajr!.difference(pt.maghrib!);
      add(
          "Tahajjud",
          pt.maghrib!.add(Duration(seconds: (night.inSeconds * 0.75).toInt())),
          false);
    }

    timesList.sort((a, b) =>
        (a["dateTime"] as DateTime).compareTo(b["dateTime"] as DateTime));
    fardList.sort((a, b) =>
        (a["dateTime"] as DateTime).compareTo(b["dateTime"] as DateTime));

    return {
      "location": locationName,
      "timesList": timesList,
      "fardList": fardList,
      "sunrise": pt.sunrise?.toLocal(),
      "nextFajr": ptTomorrow.fajr?.toLocal(),
    };
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.selectedSecondary,
      appBar: AppBar(
        title: Column(
          children: [
            const Text("PRAYER TIME",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 16)),
            Text(DateFormat("h:mm:ss a").format(DateTime.now()),
                style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.selectedTheme,
                    fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            onPressed: () {
              if (_lastData != null) {
                AppShare.namazTimes(
                  context: context,
                  bloc: themeProvider,
                  location: _lastData!["location"],
                  date: DateFormat("EEEE, d MMMM yyyy").format(DateTime.now()),
                  times: _lastData!["timesList"],
                );
              }
            },
            icon: Icon(Icons.share_rounded, color: themeProvider.selectedTheme),
          ),
          IconButton(
            onPressed: () => push(context, const DirectionTOQiblah()),
            icon: Icon(Icons.compass_calibration_rounded,
                color: themeProvider.selectedTheme),
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _prayerCacheFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _lastData == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text("Error Loading Times\n${snapshot.error}",
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                      onPressed: _refreshData, child: const Text("Retry"))
                ],
              ),
            ));
          }

          final data = snapshot.data ?? _lastData!;
          _lastData = data;

          final now = DateTime.now();
          final List<Map<String, dynamic>> fardList = data["fardList"];
          final DateTime? sunrise = data["sunrise"];
          final DateTime? nextFajr = data["nextFajr"];

          // logic for current and next FARZ explicitly
          String currentFarz = "";
          DateTime? currentFarzEnd;
          String nextFarz = "";
          DateTime? nextFarzStart;

          // Standard Farz Sequence logic
          for (var i = 0; i < fardList.length; i++) {
            final DateTime time = fardList[i]["dateTime"]; // Local
            if (time.isAfter(now)) {
              nextFarz = fardList[i]["name"];
              nextFarzStart = time;
              if (i > 0) {
                currentFarz = fardList[i - 1]["name"];
                // Special Rule: Fajr ends at Sunrise
                currentFarzEnd = (currentFarz == "Fajr") ? sunrise : time;
              } else {
                // Before Fajr (Night)
                currentFarz = "Isha (Passing)";
                currentFarzEnd = fardList[0]["dateTime"];
              }
              break;
            }
          }

          // Case: After Isha
          if (nextFarz.isEmpty) {
            currentFarz = "Isha";
            nextFarz = "Fajr";
            nextFarzStart = nextFajr;
          }

          // Header Logic
          String label = "";
          String timeStr = "";

          // Focus logic: If we are in an active window of a farz prayer, show its end
          if (currentFarz.isNotEmpty &&
              currentFarzEnd != null &&
              now.isBefore(currentFarzEnd)) {
            label = "$currentFarz Time Ends In";
            timeStr = _formatDuration(currentFarzEnd.difference(now));
          } else {
            label = "Upcoming ($nextFarz) Starts In";
            if (nextFarzStart != null) {
              timeStr = _formatDuration(nextFarzStart.difference(now));
            }
          }

          final List<Map<String, dynamic>> displayList =
              _showFardOnly ? fardList : data["timesList"];

          return RefreshIndicator(
            onRefresh: () async => _refreshData(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            themeProvider.selectedTheme,
                            themeProvider.selectedTheme.withOpacity(0.8)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color:
                                  themeProvider.selectedTheme.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: Colors.white70, size: 18),
                              const SizedBox(width: 8),
                              Text(data["location"],
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text(label,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Text(timeStr,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1)),
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () =>
                                push(context, const DirectionTOQiblah()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(40)),
                              child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.explore_outlined,
                                        color: Colors.white, size: 16),
                                    SizedBox(width: 8),
                                    Text("Check Qibla Direction",
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500)),
                                  ]),
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Fiqa / Madhab",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.grey)),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _madhabChip("Hanafi", "hanafi", themeProvider),
                            const SizedBox(width: 12),
                            _madhabChip(
                                "Shafi / Standard", "shafi", themeProvider),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Daily Schedule",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Color(0xFF2D3436))),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4)
                              ]),
                          child: Row(
                            children: [
                              _toggleItem(
                                  "Farz",
                                  _showFardOnly,
                                  () => setState(() => _showFardOnly = true),
                                  themeProvider),
                              _toggleItem(
                                  "All",
                                  !_showFardOnly,
                                  () => setState(() => _showFardOnly = false),
                                  themeProvider),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final prayer = displayList[index];
                        final String name = prayer["name"];
                        final DateTime dateTime = prayer["dateTime"];
                        final bool isFard = prayer["isFard"];

                        // Active check
                        bool activeNow = (name == currentFarz);
                        // If it's Fajr window (past start, before sunrise)
                        if (name == "Fajr" &&
                            now.isAfter(dateTime) &&
                            sunrise != null &&
                            now.isBefore(sunrise)) activeNow = true;
                        // For Zuhr, Asr etc, it's active until next Farz

                        final bool isPassed =
                            dateTime.isBefore(now) && !activeNow;

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                                color: activeNow
                                    ? themeProvider.selectedTheme
                                    : Colors.transparent,
                                width: 2),
                            boxShadow: [
                              activeNow
                                  ? BoxShadow(
                                      color: themeProvider.selectedTheme
                                          .withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4))
                                  : BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2))
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 8),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                  color: activeNow
                                      ? themeProvider.selectedTheme
                                      : const Color(0xFFF1F2F6),
                                  shape: BoxShape.circle),
                              child: Icon(_getPrayerIcon(name),
                                  color: activeNow
                                      ? Colors.white
                                      : const Color(0xFF747D8C),
                                  size: 22),
                            ),
                            title: Row(
                              children: [
                                Text(name,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                        color: isPassed
                                            ? const Color(0xFFA4B0BE)
                                            : const Color(0xFF2D3436))),
                                if (!isFard) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                        color: themeProvider.selectedTheme
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4)),
                                    child: Text("Optional",
                                        style: TextStyle(
                                            color: themeProvider.selectedTheme,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold)),
                                  )
                                ]
                              ],
                            ),
                            subtitle: activeNow
                                ? Text("• Active Now",
                                    style: TextStyle(
                                        color: themeProvider.selectedTheme,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold))
                                : null,
                            trailing: Text(prayer["time"],
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: activeNow
                                        ? themeProvider.selectedTheme
                                        : (isPassed
                                            ? const Color(0xFFA4B0BE)
                                            : const Color(0xFF57606F)))),
                          ),
                        );
                      },
                      childCount: displayList.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _madhabChip(String label, String value, ThemeProvider tp) {
    bool isSelected = _madhab == value;
    return GestureDetector(
      onTap: () async {
        if (!isSelected) {
          setState(() {
            _madhab = value;
          });
          await SavedPrefernces.setMadhab(value);
          _refreshData();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? tp.selectedTheme : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isSelected ? tp.selectedTheme : Colors.grey.shade300),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: tp.selectedTheme.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _toggleItem(
      String label, bool active, VoidCallback onTap, ThemeProvider tp) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
            color: active ? tp.selectedTheme : Colors.transparent,
            borderRadius: BorderRadius.circular(30)),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.bold,
                fontSize: 11)),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.isNegative) return "00h 00m";
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    return "${hours.toString().padLeft(2, '0')}h ${minutes.toString().padLeft(2, '0')}m";
  }

  IconData _getPrayerIcon(String name) {
    switch (name) {
      case "Tahajjud":
        return Icons.brightness_3_rounded;
      case "Fajr":
        return Icons.nights_stay_rounded;
      case "Ishraq":
        return Icons.wb_sunny_outlined;
      case "Chasht":
        return Icons.sunny_snowing;
      case "Zuhr":
        return Icons.wb_sunny_rounded;
      case "Asr":
        return Icons.wb_cloudy_rounded;
      case "Maghrib":
        return Icons.wb_twilight_rounded;
      case "Awwabin":
        return Icons.auto_awesome_rounded;
      case "Isha":
        return Icons.bedtime_rounded;
      case "Witr":
        return Icons.star_rounded;
      default:
        return Icons.access_time_filled_rounded;
    }
  }
}
