import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../Provider/theme_provider.dart';
import '../Services/floating_player_bridge.dart';

/// Switch for keeping the Iqra logo floating over other apps while a
/// recitation plays and the app is minimized. Turning it on without the
/// "Display over other apps" permission opens the page that grants it.
class FloatOverAppsTile extends StatefulWidget {
  const FloatOverAppsTile({super.key});

  @override
  State<FloatOverAppsTile> createState() => _FloatOverAppsTileState();
}

class _FloatOverAppsTileState extends State<FloatOverAppsTile>
    with WidgetsBindingObserver {
  bool _granted = false;
  // Turn on once the listener comes back from granting the permission.
  bool _enableOnReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final granted = await FloatingPlayerBridge.canDrawOverlays();
    if (!mounted) return;
    setState(() => _granted = granted);
    if (granted && _enableOnReturn) {
      _enableOnReturn = false;
      await FloatingPlayerBridge.setEnabled(true);
    }
  }

  Future<void> _onChanged(bool on) async {
    if (!on) {
      _enableOnReturn = false;
      await FloatingPlayerBridge.setEnabled(false);
      return;
    }
    if (_granted) {
      await FloatingPlayerBridge.setEnabled(true);
      return;
    }
    if (!await _explain()) return;
    _enableOnReturn = true;
    await FloatingPlayerBridge.openPermissionSettings();
  }

  Future<bool> _explain() async {
    final theme = context.read<ThemeProvider>().selectedTheme;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.picture_in_picture_alt_rounded, color: theme),
            const SizedBox(width: 10),
            const Expanded(child: Text('Float over other apps')),
          ],
        ),
        content: const Text(
            'Keep the IQRA logo on screen while you use other apps, so you '
            'can pause or change the ayah without coming back.\n\n'
            'On the next screen, turn on "Allow display over other apps" '
            'for IQRA QURAN, then come back.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (!FloatingPlayerBridge.isSupported) return const SizedBox.shrink();
    final theme = context.watch<ThemeProvider>().selectedTheme;
    return ValueListenableBuilder<bool>(
      valueListenable: FloatingPlayerBridge.enabled,
      builder: (context, enabled, _) => SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: Icon(Icons.picture_in_picture_alt_rounded, color: theme),
        title: const Text('Float over other apps'),
        subtitle: Text(
          _granted
              ? 'Keep the IQRA logo on screen when you leave the app'
              : 'Needs "Display over other apps" permission',
          style: const TextStyle(fontSize: 12),
        ),
        value: enabled && _granted,
        activeColor: theme,
        onChanged: _onChanged,
      ),
    );
  }
}
