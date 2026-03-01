import 'package:flutter/material.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/theme_provider.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _viewDate = DateTime.now();
  final List<String> _weekDays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT'
  ];

  void _nextMonth() {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month + 1, 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _viewDate = DateTime(_viewDate.year, _viewDate.month - 1, 1);
    });
  }

  String _getHijriRange(ThemeProvider themeProvider) {
    final firstDay = DateTime(_viewDate.year, _viewDate.month, 1);
    final lastDay = DateTime(_viewDate.year, _viewDate.month + 1, 0);

    final hFirst = HijriCalendar.fromDate(
        firstDay.add(Duration(days: themeProvider.hijriOffset)));
    final hLast = HijriCalendar.fromDate(
        lastDay.add(Duration(days: themeProvider.hijriOffset)));

    String getFullMonth(int m) {
      final names = {
        1: "Muharram-ul-Haram",
        2: "Safar-ul-Muzaffar",
        3: "Rabi-ul-Awwal",
        4: "Rabi-us-Sani",
        5: "Jumada-ul-Awwal",
        6: "Jumada-us-Sani",
        7: "Rajab-ul-Murajab",
        8: "Shaban-ul-Moazzam",
        9: "Ramadan-ul-Mubarak",
        10: "Shawwal-ul-Mukarram",
        11: "Zilqad-tul-Haram",
        12: "Zil-Hajj-tul-Haram",
      };
      return names[m] ??
          HijriCalendar.fromDate(
                  DateTime.now().add(Duration(days: themeProvider.hijriOffset)))
              .longMonthName;
    }

    if (hFirst.hMonth == hLast.hMonth) {
      return "${getFullMonth(hFirst.hMonth)} ${hFirst.hYear}";
    } else {
      return "${getFullMonth(hFirst.hMonth)} / ${getFullMonth(hLast.hMonth)} ${hFirst.hYear}";
    }
  }

  @override
  Widget build(BuildContext context) {
    var themeProvider = context.watch<ThemeProvider>();
    final color = themeProvider.selectedTheme;

    // Calendar math
    final firstDayOfMonth = DateTime(_viewDate.year, _viewDate.month, 1);
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7; // 0 for Sunday

    // Total cells in grid (offset + days)
    final totalCells = startingWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: color,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        centerTitle: true,
        title: const Text(
          "Calendar",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header Navigation
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              color: color,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.arrow_circle_left_outlined,
                            color: Colors.white, size: 35),
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(_viewDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.arrow_circle_right_outlined,
                            color: Colors.white, size: 35),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 25, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _getHijriRange(themeProvider),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Day Headers
            Container(
              color: color.withOpacity(0.9),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: _weekDays
                    .map((day) => Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),

            // Calendar Grid with Backdrop Image
            Expanded(
              child: Stack(
                children: [
                  // Background Image
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.3,
                      child: Image.asset(
                        'assets/images/masjid1.png', // Using available masjid image
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Grid
                  GridView.builder(
                    padding: const EdgeInsets.all(4),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: 0.65,
                    ),
                    itemCount: rows * 7,
                    itemBuilder: (context, index) {
                      final dayNumber = index - startingWeekday + 1;
                      final isValidDay =
                          dayNumber > 0 && dayNumber <= daysInMonth;

                      if (!isValidDay) {
                        return const SizedBox.shrink();
                      }

                      final date =
                          DateTime(_viewDate.year, _viewDate.month, dayNumber);
                      final hijri = HijriCalendar.fromDate(
                          date.add(Duration(days: themeProvider.hijriOffset)));
                      final isToday = DateUtils.isSameDay(date, DateTime.now());

                      return Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isToday
                              ? color.withOpacity(0.4)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isToday
                                ? Colors.white
                                : Colors.white.withOpacity(0.1),
                            width: isToday ? 1.5 : 0.5,
                          ),
                        ),
                        child: Stack(
                          children: [
                            // Gregorian Date (English)
                            Positioned(
                              top: 6,
                              left: 8,
                              child: Text(
                                "$dayNumber",
                                style: TextStyle(
                                  color: isToday
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ),

                            // Hijri Date (Arabic)
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(height: 10),
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: BoxDecoration(
                                      color: isToday
                                          ? Colors.white
                                          : color.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${hijri.hDay}",
                                        style: TextStyle(
                                          color: isToday ? color : Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Hijri",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
