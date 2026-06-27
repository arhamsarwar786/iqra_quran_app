import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Models/tasbeeh_model.dart';
import 'package:iqra/Provider/tasbeeh_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Services/analytics_service.dart';
import 'package:iqra/main.dart';

class TasheehListScreen extends StatefulWidget {
  const TasheehListScreen({Key? key}) : super(key: key);

  @override
  State<TasheehListScreen> createState() => _TasheehListScreenState();
}

class _TasheehListScreenState extends State<TasheehListScreen> {
  List<TasbeehModel> tasbeehList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasbeehData();
  }

  /// Load tasbeehs from JSON, then bubble the recently-used ones to the top.
  Future<void> loadTasbeehData() async {
    try {
      final String response =
          await rootBundle.loadString('assets/json_data/tasbeeh.json');
      final List<dynamic> data = json.decode(response);
      final List<TasbeehModel> all =
          data.map((item) => TasbeehModel.fromJson(item)).toList();

      // --- Fetch ObjectBox records sorted newest-first -----------------------
      // We stream once synchronously via a query to get the current snapshot.
      final savedRecords = objectbox.getAllUsersSortedByDate();

      // Build a set of arabic strings that have been used recently (newest first)
      final recentArabic = savedRecords
          .map((r) => r.virdh?.trim() ?? '')
          .where((v) => v.isNotEmpty)
          .toList();

      // Deduplicate while preserving order (first occurrence = most recent)
      final seenInRecent = <String>{};
      final recentUniqueArabic = <String>[];
      for (final a in recentArabic) {
        if (seenInRecent.add(a)) recentUniqueArabic.add(a);
      }

      // Split all tasbeehs into "hajj", "recent" and "rest"
      final List<TasbeehModel> hajjItems = [];
      final List<TasbeehModel> recentItems = [];
      final List<TasbeehModel> restItems = [];

      for (final t in all) {
        if (t.no == "1" || t.no == "2") {
          hajjItems.add(t);
        } else {
          final arabic = t.arabic?.trim() ?? '';
          if (recentUniqueArabic.contains(arabic)) {
            recentItems.add(t);
          } else {
            restItems.add(t);
          }
        }
      }

      // Sort recentItems to match the most-recently-used order
      recentItems.sort((a, b) {
        final idxA = recentUniqueArabic.indexOf(a.arabic?.trim() ?? '');
        final idxB = recentUniqueArabic.indexOf(b.arabic?.trim() ?? '');
        return idxA.compareTo(idxB);
      });

      setState(() {
        // Hajj-specific tasbeehs appear last after the season
        tasbeehList = [...recentItems, ...restItems, ...hajjItems];
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading tasbeeh data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    var bloc = context.read<ThemeProvider>();
    // Also read current selected tasbeeh for duplicate detection
    final currentSelected = context.read<TasbeehProvider>().selectedTasbeeh;

    return Scaffold(
      backgroundColor: bloc.selectedSecondary,
      appBar: AppBar(
        backgroundColor: bloc.selectedTheme,
        title: const Text("Tasbeeh"),
        centerTitle: true,
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.only(top: 10),
                child: ListView.builder(
                  itemCount: tasbeehList.length,
                  itemBuilder: (context, index) {
                    final tasbeeh = tasbeehList[index];

                    // Is this the one currently active?
                    final isCurrentlySelected =
                        currentSelected?.arabic?.trim() ==
                            tasbeeh.arabic?.trim();

                    return InkWell(
                      onTap: () {
                        AnalyticsService.trackFeatureAccess('tasbeeh');
                        var tasbeehProvider = context.read<TasbeehProvider>();
                        var tasbihCountProvider = context.read<TasbeeCount>();
                        final currentTasbeeh = tasbeehProvider.selectedTasbeeh;

                        // ── DUPLICATE GUARD ──────────────────────────────────
                        // If user taps the already-selected tasbeeh, just close
                        // the screen without resetting the counter.
                        if (currentTasbeeh?.arabic?.trim() ==
                            tasbeeh.arabic?.trim()) {
                          Navigator.pop(context);
                          return;
                        }

                        // Save current progress before switching
                        if (currentTasbeeh != null &&
                            currentTasbeeh.arabic != null) {
                          objectbox.saveDailyTasbih(currentTasbeeh.arabic!,
                              tasbihCountProvider.currentStep.toInt());
                        }

                        // Check if this tasbeeh has today's saved progress
                        final todayRecord = objectbox
                            .getTodayTasbih(tasbeeh.arabic?.trim() ?? '');

                        // Set new tasbeeh
                        tasbeehProvider.setSelectedTasbeeh(tasbeeh);

                        // Restore today's count if it exists, else start at 0
                        tasbihCountProvider.setValue(todayRecord?.count ?? 0);

                        Navigator.pop(context);
                      },
                      child: _TasbeehCard(
                        tasbeeh: tasbeeh,
                        bloc: bloc,
                        isActive: isCurrentlySelected,
                      ),
                    );
                  },
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Widget
// ─────────────────────────────────────────────────────────────────────────────

class _TasbeehCard extends StatelessWidget {
  const _TasbeehCard({
    required this.tasbeeh,
    required this.bloc,
    required this.isActive,
    Key? key,
  }) : super(key: key);

  final TasbeehModel tasbeeh;
  final ThemeProvider bloc;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final baseColor = bloc.selectedTheme;

    return Container(
      margin: const EdgeInsets.only(left: 10, right: 10, top: 10),
      padding: const EdgeInsets.all(15),
      constraints: const BoxConstraints(minHeight: 80),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isActive ? baseColor.withOpacity(0.75) : baseColor,
        border: isActive
            ? Border.all(color: const Color(0xFFFFD700), width: 2.5)
            : null,
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: baseColor.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          isActive
              ? const Icon(Icons.check_circle_rounded,
                  size: 28, color: Color(0xFFFFD700))
              : Icon(Icons.chevron_left_outlined,
                  size: 30, color: MyColors.whiteColor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  tasbeeh.arabic ?? '',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: bloc.arabicFontFamily,
                    fontSize: 32,
                    color: MyColors.whiteColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  tasbeeh.urduMeaning ?? '',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: bloc.urduFontFamily,
                    fontSize: 20,
                    color: MyColors.whiteColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
