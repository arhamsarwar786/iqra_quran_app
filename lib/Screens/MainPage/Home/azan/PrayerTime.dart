import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:provider/provider.dart';
import '../../../../Provider/theme_provider.dart';
import '../../../../widgets.dart';
import '../../../../Utils/share_verse.dart';
import '../../../../Helper/preference/saved_preferences.dart';
import '../../../../Services/prayer_notification_service.dart';
import '../qibal/qibla.dart';
import '../../Drawer/setting_screen.dart';

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
  String _calcMethod = 'karachi';
  bool _notificationsEnabled = true;
  Map<String, bool> _prayerToggles = {
    'fajr': true,
    'zuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initMadhab();
    _loadPrayerToggles();
    _prayerCacheFuture = _getPrayerData();
    // Update every second for the clock, calculations are light
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeNotifications() async {
    await PrayerNotificationService.initialize();
    bool enabled = await SavedPrefernces.getPrayerNotificationsEnabled();
    if (mounted) {
      setState(() {
        _notificationsEnabled = enabled;
      });
    }
  }

  Future<void> _initMadhab() async {
    final String m = await SavedPrefernces.getMadhab();
    final String c = await SavedPrefernces.getCalculationMethod();
    if (mounted) {
      setState(() {
        _madhab = m;
        _calcMethod = c;
        _refreshData();
      });
    }
  }

  Future<void> _loadPrayerToggles() async {
    final toggles = await SavedPrefernces.getAllPrayerNotificationToggles();
    if (mounted) setState(() => _prayerToggles = toggles);
  }

  Future<void> _togglePrayerNotif(String prayerKey, bool value) async {
    await SavedPrefernces.setPrayerNotificationEnabled(prayerKey, value);
    setState(() => _prayerToggles[prayerKey] = value);
    if (_currentPosition != null) {
      await PrayerNotificationService.scheduleAllPrayers(
        position: _currentPosition!,
        madhab: _madhab,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(value
            ? '🔔 ${_capitalize(prayerKey)} notification ON'
            : '🔕 ${_capitalize(prayerKey)} notification OFF'),
        duration: const Duration(seconds: 2),
        backgroundColor: value ? Colors.green.shade600 : Colors.grey.shade700,
      ));
    }
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

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

    // Calculation — use saved method (default: Karachi = authentic for Pakistan)
    Coordinates coordinates =
        Coordinates(position.latitude, position.longitude);

    CalculationParameters params;
    switch (_calcMethod) {
      case 'karachi':
        params = CalculationMethodParameters.karachi();
        break;
      case 'mwl':
        params = CalculationMethodParameters.muslimWorldLeague();
        break;
      case 'isna':
        params = CalculationMethodParameters.northAmerica();
        break;
      case 'egypt':
        params = CalculationMethodParameters.egyptian();
        break;
      case 'makkah':
      case 'umm_al_qura':
        params = CalculationMethodParameters.ummAlQura();
        break;
      case 'dubai':
        params = CalculationMethodParameters.dubai();
        break;
      case 'turkey':
      case 'turkiye':
        params = CalculationMethodParameters.turkiye();
        break;
      case 'tehran':
        params = CalculationMethodParameters.tehran();
        break;
      case 'singapore':
        params = CalculationMethodParameters.singapore();
        break;
      default:
        params = CalculationMethodParameters.karachi();
    }
    params.madhab = _madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;

    // Debug: Print madhab being used
    print('🕌 Calculating prayer times with madhab: $_madhab');
    print('📍 Location: ${position.latitude}, ${position.longitude}');

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

    // Debug: Print Asr time to verify madhab difference
    if (pt.asr != null) {
      print(
          '⏰ Asr time ($_madhab): ${DateFormat("h:mm a").format(pt.asr!.toLocal())}');
    }

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

    // Store position for notification scheduling
    _currentPosition = position;

    // Schedule notifications if enabled (with current method + madhab)
    if (_notificationsEnabled) {
      await PrayerNotificationService.scheduleAllPrayers(
        position: position,
        madhab: _madhab,
      );
    }

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

    return SafeArea(
      child: Scaffold(
        backgroundColor: themeProvider.selectedSecondary,
        appBar: AppBar(
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: themeProvider.selectedTheme),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            children: [
              Text("PRAYER TIME",
                  style: TextStyle(
                      color: themeProvider.selectedTheme,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      fontSize: 18)),
              Container(
                margin: const EdgeInsets.only(top: 2),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 1),
                decoration: BoxDecoration(
                  color: themeProvider.selectedTheme.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(DateFormat("h:mm:ss a").format(DateTime.now()),
                    style: TextStyle(
                        fontSize: 11,
                        color: themeProvider.selectedTheme,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold)),
              ),
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
                    date:
                        DateFormat("EEEE, d MMMM yyyy").format(DateTime.now()),
                    times: _lastData!["timesList"],
                  );
                }
              },
              icon:
                  Icon(Icons.share_rounded, color: themeProvider.selectedTheme),
            ),
            IconButton(
              onPressed: () => push(context, const DirectionTOQiblah()),
              icon: Icon(Icons.compass_calibration_rounded,
                  color: themeProvider.selectedTheme),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => push(context, const SettingScreen()),
              icon: Icon(Icons.settings_outlined,
                  color: themeProvider.selectedTheme),
            )
          ],
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          key: ValueKey(_madhab), // Force rebuild when madhab changes
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
                    const Icon(Icons.error_outline,
                        size: 48, color: Colors.red),
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
                              themeProvider.selectedTheme.withOpacity(0.9),
                              themeProvider.selectedTheme.withOpacity(0.85)
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(40),
                          boxShadow: [
                            BoxShadow(
                                color: themeProvider.selectedTheme
                                    .withOpacity(0.4),
                                blurRadius: 25,
                                offset: const Offset(0, 15))
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(40),
                          child: Stack(
                            children: [
                              // Subtle background decoration
                              Positioned(
                                right: -40,
                                top: -40,
                                child: Icon(
                                  Icons.mosque_rounded,
                                  size: 200,
                                  color: Colors.white.withOpacity(0.1),
                                ),
                              ),
                              Positioned(
                                left: -20,
                                bottom: -20,
                                child: Icon(
                                  Icons.nights_stay_rounded,
                                  size: 100,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(28.0),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.location_on_rounded,
                                            color: Colors.white, size: 16),
                                        const SizedBox(width: 8),
                                        Text(data["location"].toUpperCase(),
                                            style: TextStyle(
                                                color: Colors.white
                                                    .withOpacity(0.9),
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 2.0,
                                                fontSize: 12)),
                                      ],
                                    ),
                                    const SizedBox(height: 25),
                                    Text(label.toUpperCase(),
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7),
                                            fontSize: 11,
                                            letterSpacing: 2.0,
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 10),
                                    ShaderMask(
                                      shaderCallback: (bounds) =>
                                          const LinearGradient(
                                        colors: [
                                          Colors.white,
                                          Color(0xFFE0E0E0)
                                        ],
                                      ).createShader(bounds),
                                      child: Text(timeStr,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 60,
                                              fontFamily: 'Roboto',
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -2)),
                                    ),
                                    const SizedBox(height: 25),
                                    GestureDetector(
                                      onTap: () => push(
                                          context, const DirectionTOQiblah()),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
                                        decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(40),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.15),
                                                blurRadius: 15,
                                              )
                                            ]),
                                        child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.explore_outlined,
                                                  color: themeProvider
                                                      .selectedTheme,
                                                  size: 20),
                                              const SizedBox(width: 12),
                                              Text("QIBLA DIRECTION",
                                                  style: TextStyle(
                                                      color: themeProvider
                                                          .selectedTheme,
                                                      fontSize: 13,
                                                      letterSpacing: 1.5,
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            ]),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: activeNow
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: activeNow
                                    ? themeProvider.selectedTheme
                                        .withOpacity(0.3)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                    color: activeNow
                                        ? themeProvider.selectedTheme
                                            .withOpacity(0.15)
                                        : Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5))
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: activeNow
                                        ? themeProvider.selectedTheme
                                        : themeProvider.selectedTheme
                                            .withOpacity(0.08),
                                    shape: BoxShape.circle),
                                child: Icon(_getPrayerIcon(name),
                                    color: activeNow
                                        ? Colors.white
                                        : themeProvider.selectedTheme
                                            .withOpacity(0.7),
                                    size: 22),
                              ),
                              title: Row(
                                children: [
                                  Text(name,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 17,
                                          color: isPassed
                                              ? const Color(0xFFA4B0BE)
                                              : const Color(0xFF2D3436))),
                                  if (!isFard) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                      child: const Text("NAFL",
                                          style: TextStyle(
                                              color: Colors.orange,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1)),
                                    )
                                  ]
                                ],
                              ),
                              subtitle: activeNow
                                  ? Text("• CURRENT PRAYER",
                                      style: TextStyle(
                                          color: themeProvider.selectedTheme,
                                          fontSize: 10,
                                          letterSpacing: 0.5,
                                          fontWeight: FontWeight.w900))
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isFard) ...[
                                    GestureDetector(
                                      onTap: () {
                                        final key = name.toLowerCase();
                                        final current =
                                            _prayerToggles[key] ?? true;
                                        _togglePrayerNotif(key, !current);
                                      },
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 250),
                                        child: Icon(
                                          (_prayerToggles[name.toLowerCase()] ??
                                                  true)
                                              ? Icons
                                                  .notifications_active_rounded
                                              : Icons
                                                  .notifications_off_outlined,
                                          key: ValueKey(_prayerToggles[
                                              name.toLowerCase()]),
                                          color: (_prayerToggles[
                                                      name.toLowerCase()] ??
                                                  true)
                                              ? themeProvider.selectedTheme
                                              : Colors.grey.shade300,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 15),
                                  ],
                                  Text(prayer["time"],
                                      style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 18,
                                          fontFamily: 'Roboto',
                                          color: activeNow
                                              ? themeProvider.selectedTheme
                                              : (isPassed
                                                  ? const Color(0xFFA4B0BE)
                                                  : const Color(0xFF57606F)))),
                                ],
                              ),
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
      ),
    );
  }

  Widget _madhabChip(String label, String value, ThemeProvider tp) {
    bool isSelected = _madhab == value;
    return GestureDetector(
      onTap: () async {
        if (!isSelected) {
          // Clear cached data first
          _lastData = null;

          setState(() {
            _madhab = value;
          });

          await SavedPrefernces.setMadhab(value);

          // Force refresh with new madhab
          _refreshData();

          // Show feedback
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Switched to $label - Recalculating prayer times...'),
                duration: const Duration(seconds: 2),
                backgroundColor: tp.selectedTheme,
              ),
            );
          }

          // Reschedule notifications with new madhab if enabled
          if (_notificationsEnabled && _currentPosition != null) {
            await PrayerNotificationService.scheduleAllPrayers(
              position: _currentPosition!,
              madhab: value,
            );
          }
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
    if (duration.isNegative) return "00:00:00";
    int hours = duration.inHours;
    int minutes = duration.inMinutes.remainder(60);
    int seconds = duration.inSeconds.remainder(60);
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
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
