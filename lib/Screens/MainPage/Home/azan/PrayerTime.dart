import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../Provider/theme_provider.dart';
import '../../../../widgets.dart';
import '../../../../Utils/share_verse.dart';
import '../../../../Helper/preference/saved_preferences.dart';
import '../../../../Services/prayer_notification_service.dart';
import '../qibal/qibla.dart';
import '../../Drawer/setting_screen.dart';

import 'package:iqra/Provider/prayer_provider.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../Services/analytics_service.dart';

class PrayerTime extends StatefulWidget {
  const PrayerTime({Key? key}) : super(key: key);

  @override
  State<PrayerTime> createState() => _PrayerTimeState();
}

class _PrayerTimeState extends State<PrayerTime> {
  Timer? _timer;
  bool _showFardOnly = true;
  String _madhab = 'hanafi';
  Map<String, bool> _prayerToggles = {
    'fajr': true,
    'zuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _initMadhab();
    _loadPrayerToggles();

    // Update every second for the countdown clock
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _initializeNotifications() async {
    await PrayerNotificationService.initialize();
  }

  Future<void> _initMadhab() async {
    final String m = await SavedPrefernces.getMadhab();
    if (mounted) {
      setState(() {
        _madhab = m;
      });
      // Ensure provider has the latest data if madhab might have changed
      context.read<PrayerProvider>().fetchPrayerData(forceRefresh: true);
    }
  }

  Future<void> _loadPrayerToggles() async {
    final toggles = await SavedPrefernces.getAllPrayerNotificationToggles();
    if (mounted) setState(() => _prayerToggles = toggles);
  }

  Future<void> _togglePrayerNotif(String prayerKey, bool value) async {
    await SavedPrefernces.setPrayerNotificationEnabled(prayerKey, value);
    setState(() => _prayerToggles[prayerKey] = value);

    final prayerProvider = context.read<PrayerProvider>();
    final position = prayerProvider.prayerData?['position'];

    if (position != null) {
      await PrayerNotificationService.scheduleAllPrayers(
        position: position,
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
            Consumer<PrayerProvider>(builder: (context, provider, _) {
              return IconButton(
                onPressed: () {
                  if (provider.prayerData != null) {
                    AnalyticsService.logEvent('share_prayer_times');
                    AppShare.namazTimes(
                      context: context,
                      bloc: themeProvider,
                      location: provider.prayerData!["location"],
                      date: DateFormat("EEEE, d MMMM yyyy")
                          .format(DateTime.now()),
                      times: provider.prayerData!["timesList"],
                    );
                  }
                },
                icon: Icon(Icons.share_rounded,
                    color: themeProvider.selectedTheme),
              );
            }),
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
        body: Consumer<PrayerProvider>(
          builder: (context, prayerProvider, child) {
            final data = prayerProvider.prayerData;
            if (prayerProvider.isLoading && data == null) {
              return const Center(child: CircularProgressIndicator());
            }
            if (prayerProvider.error != null && data == null) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Glowing Warning Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 5,
                          )
                        ],
                      ),
                      child: const Icon(
                        Icons.location_off_rounded,
                        size: 64,
                        color: Colors.redAccent,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "Location Unavailable",
                      style: TextStyle(
                        color: themeProvider.selectedTheme,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      prayerProvider.error != null &&
                              prayerProvider.error!
                                  .contains('permanently denied')
                          ? "Location access is permanently disabled. Please enable it in your phone settings to see prayer times."
                          : (prayerProvider.error ??
                              "We couldn't determine your location to calculate prayer times. Please ensure GPS is enabled."),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Glassmorphism Styled Action Button
                    ElevatedButton(
                      onPressed: () async {
                        AnalyticsService.logEvent('location_error_action');
                        if (prayerProvider.error != null &&
                            prayerProvider.error!
                                .contains('permanently denied')) {
                          await Geolocator.openAppSettings();
                        } else {
                          prayerProvider.fetchPrayerData(forceRefresh: true);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: themeProvider.selectedTheme,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 48, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                        shadowColor:
                            themeProvider.selectedTheme.withOpacity(0.4),
                      ),
                      child: Text(
                        prayerProvider.error != null &&
                                prayerProvider.error!
                                    .contains('permanently denied')
                            ? "Open Settings"
                            : "Try Again",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        "Maybe Later",
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            if (data == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final now = DateTime.now();
            final List<Map<String, dynamic>> fardList = data["fardList"];
            final DateTime sunrise = data["sunrise"];
            final DateTime nextFajr = data["nextFajr"];

            // logic for current and next FARZ explicitly
            String currentFarz = "";
            DateTime? currentFarzEnd;
            String nextFarz = "";
            DateTime? nextFarzStart;

            // Improved Active Detection: find the most recent prayer that has already started
            // We use displayList (which includes Sun/Tahajjud) for visual highlighting,
            // but currentFarz logic usually focuses on the 5 fards for the header.
            for (var i = 0; i < fardList.length; i++) {
              final DateTime time = fardList[i]["dateTime"]; // Local
              if (time.isAfter(now)) {
                nextFarz = fardList[i]["name"];
                nextFarzStart = time;
                if (i > 0) {
                  currentFarz = fardList[i - 1]["name"];
                  currentFarzEnd = (currentFarz == "Fajr") ? sunrise : time;
                } else {
                  // If before first prayer of the day, last prayer was Isha
                  currentFarz = "Isha";
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
              // Isha ends at next fajr (or midnight depending on preference, but fajr is safe)
              currentFarzEnd = nextFajr;
            }

            // Header Logic
            String label = "";
            String timeStr = "";

            if (now.isBefore(fardList[0]["dateTime"])) {
              label = "Upcoming (Fajr) Starts In";
              timeStr =
                  _formatDuration(fardList[0]["dateTime"].difference(now));
            } else if (currentFarz.isNotEmpty &&
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
              onRefresh: () async =>
                  prayerProvider.fetchPrayerData(forceRefresh: true),
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
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
                                    ),
                                    const SizedBox(height: 25),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(label.toUpperCase(),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          style: TextStyle(
                                              color:
                                                  Colors.white.withOpacity(0.7),
                                              fontSize: 11,
                                              letterSpacing: 2.0,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    const SizedBox(height: 10),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                          colors: [
                                            Colors.white,
                                            Color(0xFFE0E0E0)
                                          ],
                                        ).createShader(bounds),
                                        child: Text(timeStr,
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 50,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -2)),
                                      ),
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
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
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
                          Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            children: [
                              _madhabChip("Hanafi", "hanafi", themeProvider),
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
                          Flexible(
                            child: Text("Daily Schedule",
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Color(0xFF2D3436))),
                          ),
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
                                  Expanded(
                                    child: Text(name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 17,
                                            color: isPassed
                                                ? const Color(0xFFA4B0BE)
                                                : const Color(0xFF2D3436))),
                                  ),
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
                              trailing: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
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
                                            (_prayerToggles[
                                                        name.toLowerCase()] ??
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
                                            color: activeNow
                                                ? themeProvider.selectedTheme
                                                : (isPassed
                                                    ? const Color(0xFFA4B0BE)
                                                    : const Color(
                                                        0xFF57606F)))),
                                  ],
                                ),
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

  Widget _toggleItem(
      String title, bool active, VoidCallback onTap, ThemeProvider theme) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: active ? theme.selectedTheme : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(title,
            style: TextStyle(
                color: active ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12)),
      ),
    );
  }

  Widget _madhabChip(String title, String val, ThemeProvider theme) {
    bool active = _madhab == val;
    return GestureDetector(
      onTap: () async {
        if (!active) {
          await SavedPrefernces.setMadhab(val);
          setState(() => _madhab = val);
          Provider.of<PrayerProvider>(context, listen: false)
              .fetchPrayerData(forceRefresh: true);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Switched to $title - Recalculating prayer times...'),
                duration: const Duration(seconds: 2),
                backgroundColor: theme.selectedTheme,
              ),
            );
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: active ? theme.selectedTheme : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: active ? theme.selectedTheme : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: [
              if (active)
                BoxShadow(
                    color: theme.selectedTheme.withOpacity(0.3), blurRadius: 8)
            ]),
        child: Text(title,
            style: TextStyle(
                color: active ? Colors.white : Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold)),
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
