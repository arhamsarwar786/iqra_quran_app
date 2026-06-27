import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Services/hijri_service.dart';
import 'package:iqra/widgets/hijri_adjustment_dialog.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _viewDate;
  late DateTime _selectedDate;
  bool _syncingHijri = true;
  final List<String> _weekDays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  static const _bg = Color(0xFFF5F7FA);
  static const _cardBg = Colors.white;
  static const _textPrimary = Color(0xFF1A2332);
  static const _textSecondary = Color(0xFF6B7A90);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _viewDate = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncHijriFromLocation());
  }

  Future<void> _syncHijriFromLocation() async {
    if (!mounted) return;
    setState(() => _syncingHijri = true);

    await context.read<ThemeProvider>().refreshHijriOffset();

    if (mounted) setState(() => _syncingHijri = false);
  }

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

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _viewDate = DateTime(now.year, now.month, 1);
      _selectedDate = DateTime(now.year, now.month, now.day);
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  String _monthIslamicSubtitle(int offset) {
    final ref = DateUtils.isSameMonth(_selectedDate, _viewDate)
        ? _selectedDate
        : DateTime(_viewDate.year, _viewDate.month, 15);
    final hijri = HijriService.toHijri(ref, offset);
    return '${HijriService.monthName(hijri.hMonth)} · ${hijri.hYear} AH';
  }

  Widget _buildIslamicHero(Color color, int offset) {
    final today = DateTime.now();
    final isToday = DateUtils.isSameDay(_selectedDate, today);
    final hijri = HijriService.toHijri(_selectedDate, offset);
    final gregorian = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.82)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isToday ? 'Today' : 'Selected',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isToday)
                GestureDetector(
                  onTap: _goToToday,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Go to Today',
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${hijri.hDay}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 60,
              fontWeight: FontWeight.w300,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            HijriService.monthName(hijri.hMonth),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${hijri.hYear} AH',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              gregorian,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final color = themeProvider.selectedTheme;
    final offset = themeProvider.hijriOffset;

    final firstDayOfMonth = DateTime(_viewDate.year, _viewDate.month, 1);
    final daysInMonth = DateTime(_viewDate.year, _viewDate.month + 1, 0).day;
    final startingWeekday = firstDayOfMonth.weekday % 7;
    final totalCells = startingWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();
    final today = DateTime.now();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: _cardBg,
        foregroundColor: _textPrimary,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: _textPrimary),
        ),
        centerTitle: true,
        title: const Text(
          'Islamic Calendar',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Adjust Islamic date',
            onPressed: () => showHijriAdjustmentDialog(context),
            icon: Icon(Icons.tune_rounded, color: color),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_syncingHijri)
              LinearProgressIndicator(
                minHeight: 2,
                color: color,
                backgroundColor: color.withValues(alpha: 0.12),
              ),
            _buildIslamicHero(color, offset),

            Padding(
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _previousMonth,
                    icon: Icon(Icons.chevron_left_rounded, color: color, size: 30),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_viewDate),
                          style: const TextStyle(
                            color: _textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _monthIslamicSubtitle(offset),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _nextMonth,
                    icon: Icon(Icons.chevron_right_rounded, color: color, size: 30),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Row(
                children: _weekDays
                    .map(
                      (day) => Expanded(
                        child: Center(
                          child: Text(
                            day,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = 6.0;
                    final cellWidth =
                        (constraints.maxWidth - spacing * 6) / 7;
                    final cellHeight =
                        (constraints.maxHeight - spacing * (rows - 1)) / rows;
                    final aspectRatio = cellWidth / cellHeight;

                    return GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: spacing,
                        crossAxisSpacing: spacing,
                        childAspectRatio: aspectRatio,
                      ),
                      itemCount: rows * 7,
                      itemBuilder: (context, index) {
                        final dayNumber = index - startingWeekday + 1;
                        if (dayNumber <= 0 || dayNumber > daysInMonth) {
                          return const SizedBox.shrink();
                        }

                        final date = DateTime(
                            _viewDate.year, _viewDate.month, dayNumber);
                        final hijri = HijriService.toHijri(date, offset);
                        final isToday = DateUtils.isSameDay(date, today);
                        final isSelected =
                            DateUtils.isSameDay(date, _selectedDate);

                        return GestureDetector(
                          onTap: () => _selectDate(date),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            decoration: BoxDecoration(
                              color: isSelected ? color : _cardBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? color
                                    : isToday
                                        ? color
                                        : const Color(0xFFE2E8F0),
                                width: isSelected || isToday ? 1.8 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: color.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.75)
                                            : _textSecondary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : color.withValues(alpha: 0.12),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        '${hijri.hDay}',
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      'Hijri',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                                .withValues(alpha: 0.8)
                                            : _textSecondary,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
