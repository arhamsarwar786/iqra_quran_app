// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:iqra/Helper/preference/saved_preferences.dart';
import 'package:iqra/Services/prayer_notification_service.dart';
import 'package:iqra/Utils/customThemes.dart';
import 'package:iqra/Utils/utils.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Provider/theme_provider.dart';
import '../../../controller/methods.dart';
import '../../../Models/theme_model.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  // ── notification state ─────────────────────────────────────────────────
  bool _globalNotif = true;
  Map<String, bool> _prayerToggles = {
    'fajr': true,
    'zuhr': true,
    'asr': true,
    'maghrib': true,
    'isha': true,
  };
  String _calcMethod = 'karachi';

  bool _notifLoading = true;
  bool _testLoading = false;

  static const Map<String, String> _calcMethodLabels = {
    'karachi': 'Karachi / Pakistan (Recommended)',
    'mwl': 'Muslim World League',
    'isna': 'ISNA (North America)',
    'egypt': 'Egyptian General Authority',
  };

  static const Map<String, String> _prayerDisplayNames = {
    'fajr': 'Fajr',
    'zuhr': 'Zuhr',
    'asr': 'Asr',
    'maghrib': 'Maghrib',
    'isha': 'Isha',
  };

  @override
  void initState() {
    super.initState();
    arabicFontSize.clear();
    for (var i = 12; i <= 50; i++) {
      arabicFontSize.add(i.toDouble());
    }
    _loadNotifSettings();
  }

  Future<void> _loadNotifSettings() async {
    final global = await SavedPrefernces.getPrayerNotificationsEnabled();
    final toggles = await SavedPrefernces.getAllPrayerNotificationToggles();
    final method = await SavedPrefernces.getCalculationMethod();
    if (mounted) {
      setState(() {
        _globalNotif = global;
        _prayerToggles = toggles;
        _calcMethod = method;
        _notifLoading = false;
      });
    }
  }

  Future<void> _sendTest() async {
    setState(() => _testLoading = true);
    try {
      await PrayerNotificationService.sendTestNotification();
      snackBar(context, '🔔 Test notification sent!');
    } catch (e) {
      snackBar(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _testLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ThemeProvider>();
    return Scaffold(
      backgroundColor: bloc.selectedSecondary,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Scaffold.of(context).openDrawer(),
          icon: const Icon(Icons.menu),
        ),
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Material(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── THEME ──────────────────────────────────────────────────
                _sectionCard(
                  bloc: bloc,
                  title: 'Theme',
                  child: Row(
                    children: [
                      Text('Theme', style: MyTextStyle.heading3),
                      const Spacer(),
                      _styledDropdown(
                        bloc: bloc,
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton(
                            hint: Padding(
                              padding: const EdgeInsets.only(left: 5),
                              child: Text('Allah',
                                  style: TextStyle(color: bloc.selectedTheme)),
                            ),
                            icon: const Icon(Icons.keyboard_arrow_down),
                            items: themeList.map((items) {
                              return DropdownMenuItem(
                                value: items,
                                child: Text('Allah',
                                    style: TextStyle(
                                        color: items['primary']?.toColor(),
                                        fontWeight: FontWeight.bold)),
                              );
                            }).toList(),
                            onChanged: (Map? newValue) async {
                              final theme = ThemeModel.fromJson(newValue!);
                              final tp = Provider.of<ThemeProvider>(context,
                                  listen: false);
                              tp.changeTheme(theme.toJson());
                              snackBar(context, 'Theme Changed');
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── ARABIC FONT ────────────────────────────────────────────
                _sectionCard(
                  bloc: bloc,
                  title: 'Arabic Font',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Font Size', style: MyTextStyle.heading3),
                          const Spacer(),
                          _styledDropdown(
                            bloc: bloc,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                hint: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text('${bloc.arabicFontSize.toInt()}'),
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: arabicFontSize.map((items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text('${items.toInt()}',
                                        style: MyTextStyle.heading3),
                                  );
                                }).toList(),
                                onChanged: (newValue) async {
                                  bloc.changeArabicFont(newValue);
                                  snackBar(context, 'Arabic Font Changed!');
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        child: Text(
                          'ذٰلِكَ الۡڪِتٰبُ لَا رَيۡبَ',
                          style: TextStyle(
                              fontSize: bloc.arabicFontSize,
                              fontFamily: bloc.arabicFontFamily),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── URDU FONT ──────────────────────────────────────────────
                _sectionCard(
                  bloc: bloc,
                  title: 'Urdu Font',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Urdu Font', style: MyTextStyle.heading3),
                          const Spacer(),
                          _styledDropdown(
                            bloc: bloc,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                hint: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text(bloc.urduFontFamily),
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: urduFontFamily.map((items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text(items,
                                        style: MyTextStyle.heading3),
                                  );
                                }).toList(),
                                onChanged: (newValue) async {
                                  bloc.changeUrduFamily(newValue);
                                  snackBar(context, 'Urdu Family Changed!');
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text('Font Size', style: MyTextStyle.heading3),
                          const Spacer(),
                          _styledDropdown(
                            bloc: bloc,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                hint: Padding(
                                  padding: const EdgeInsets.only(left: 5),
                                  child: Text('${bloc.urduFontSize.toInt()}'),
                                ),
                                icon: const Icon(Icons.keyboard_arrow_down),
                                items: arabicFontSize.map((items) {
                                  return DropdownMenuItem(
                                    value: items,
                                    child: Text('${items.toInt()}',
                                        style: MyTextStyle.heading3),
                                  );
                                }).toList(),
                                onChanged: (newValue) async {
                                  bloc.changeUrduFont(newValue);
                                  snackBar(context, 'Urdu Font Changed!');
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FittedBox(
                        child: Text(
                          'تمام تعریف اللہ کے لیے ہے',
                          style: TextStyle(
                              fontSize: bloc.urduFontSize,
                              fontFamily: bloc.urduFontFamily),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── TRANSLATION ───────────────────────────────────────────
                _sectionCard(
                  bloc: bloc,
                  title: 'Translation',
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text('Translation', style: MyTextStyle.heading3),
                          const Spacer(),
                          _styledDropdown(
                            bloc: bloc,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: (bloc.selectedTranslation == "irfan" ||
                                        bloc.selectedTranslation == "hind")
                                    ? bloc.selectedTranslation
                                    : "irfan",
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(
                                      value: "irfan",
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text("Kanz-ul-Irfan",
                                            style: TextStyle(fontSize: 13)),
                                      )),
                                  DropdownMenuItem(
                                      value: "hind",
                                      child: Padding(
                                        padding: EdgeInsets.only(left: 8.0),
                                        child: Text("Kanz-ul-Iman",
                                            style: TextStyle(fontSize: 13)),
                                      )),
                                ],
                                onChanged: (val) {
                                  bloc.changeTranslation(val);
                                  snackBar(context, 'Translation Changed!');
                                  setState(() {});
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      // Preview Card
                      Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: bloc.selectedTheme.withOpacity(0.2)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'ذٰلِكَ الۡڪِتٰبُ لَا رَيۡبَ ۚۛ فِيۡهِ ۚۛ هُدًى لِّلۡمُتَّقِيۡنَ',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: bloc.arabicFontSize - 5,
                                fontFamily: bloc.arabicFontFamily,
                                color: bloc.selectedTheme,
                              ),
                            ),
                            const Divider(height: 25),
                            Text(
                              bloc.selectedTranslation == "irfan"
                                  ? "Kanz-ul-Irfan"
                                  : "Kanz-ul-Iman",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: bloc.selectedTheme,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              bloc.selectedTranslation == "irfan"
                                  ? "(یہ) وہ عظیم کتاب ہے جس میں کسی شک کی گنجائش نہیں، (یہ) پرہیزگاروں کے لیے ہدایت ہے۔"
                                  : "وہ بلند رتبہ کتاب جس میں کوئی شک کی جگہ نہیں، ہدایت ہے ڈر والوں کو۔",
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: bloc.urduFontSize - 5,
                                fontFamily: bloc.urduFontFamily,
                                color: Colors.black87,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── PRAYER NOTIFICATIONS ───────────────────────────────────
                _sectionCard(
                  bloc: bloc,
                  title: 'Prayer Notifications (Android)',
                  child: _notifLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─ Master toggle ──
                            _switchRow(
                              label: 'Enable Prayer Notifications',
                              subtitle: 'Master switch for all azan alerts',
                              value: _globalNotif,
                              color: bloc.selectedTheme,
                              onChanged: (v) async {
                                await SavedPrefernces
                                    .setPrayerNotificationsEnabled(v);
                                setState(() => _globalNotif = v);
                                snackBar(
                                    context,
                                    v
                                        ? 'Notifications enabled'
                                        : 'Notifications disabled');
                              },
                            ),

                            if (_globalNotif) ...[
                              const Divider(height: 24),

                              // ─ Calculation method ──
                              Text('Calculation Method',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: bloc.selectedTheme)),
                              const SizedBox(height: 4),
                              Text(
                                '• Karachi: used by all major Pakistani apps\n'
                                '• Hanafi vs Shafi Asr difference (~1 hr) is correct by Islamic law',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: bloc.selectedTheme, width: 1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 2),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _calcMethod,
                                    isExpanded: true,
                                    items: _calcMethodLabels.entries
                                        .map((e) => DropdownMenuItem(
                                              value: e.key,
                                              child: Text(e.value,
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                            ))
                                        .toList(),
                                    onChanged: (v) async {
                                      if (v == null) return;
                                      await SavedPrefernces
                                          .setCalculationMethod(v);
                                      setState(() => _calcMethod = v);
                                      snackBar(context,
                                          'Calculation method updated — open Prayer Times to recalculate');
                                    },
                                  ),
                                ),
                              ),

                              const Divider(height: 24),

                              // ─ Per-prayer toggles ──
                              Text('Notify for each prayer:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: bloc.selectedTheme)),
                              const SizedBox(height: 4),
                              ..._prayerDisplayNames.entries.map((e) {
                                return _switchRow(
                                  label: e.value,
                                  value: _prayerToggles[e.key] ?? true,
                                  color: bloc.selectedTheme,
                                  onChanged: (v) async {
                                    await SavedPrefernces
                                        .setPrayerNotificationEnabled(e.key, v);
                                    setState(() => _prayerToggles[e.key] = v);
                                  },
                                );
                              }),

                              const Divider(height: 24),

                              const Divider(height: 24),

                              // ─ test notification button ──
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: _testLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white))
                                      : const Icon(Icons.notifications_active),
                                  label: Text(_testLoading
                                      ? 'Sending...'
                                      : '🔔 Send Test Notification'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bloc.selectedTheme,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  onPressed: _testLoading ? null : _sendTest,
                                ),
                              ),
                            ],
                          ],
                        ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── helper widgets ────────────────────────────────────────────────────────

  Widget _sectionCard({
    required ThemeProvider bloc,
    required String title,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    color: bloc.selectedTheme)),
            Divider(color: bloc.selectedTheme),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }

  Widget _styledDropdown({required ThemeProvider bloc, required Widget child}) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(width: 1, color: bloc.selectedTheme)),
      child: child,
    );
  }

  Widget _switchRow({
    required String label,
    String? subtitle,
    required bool value,
    required Color color,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                if (subtitle != null)
                  Text(subtitle,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: color,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
