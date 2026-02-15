import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class AutoScrollSpeedDialog extends StatefulWidget {
  final double currentSpeedFactor;
  final Function(double) onSpeedChanged;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final bool isScrolling;

  const AutoScrollSpeedDialog({
    Key? key,
    required this.currentSpeedFactor,
    required this.onSpeedChanged,
    required this.onStart,
    required this.onStop,
    required this.isScrolling,
  }) : super(key: key);

  @override
  State<AutoScrollSpeedDialog> createState() => _AutoScrollSpeedDialogState();
}

class _AutoScrollSpeedDialogState extends State<AutoScrollSpeedDialog> {
  late double _speed;

  @override
  void initState() {
    super.initState();
    _speed = widget.currentSpeedFactor;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();

    return AlertDialog(
      backgroundColor: theme.selectedTheme.withOpacity(0.95), // Match theme
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      title: Text(
        "Auto Scroll Speed",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Container(
        height: 120, // Constrain height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${_speed.toStringAsFixed(1)}x",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white38,
                thumbColor: Colors.white,
                overlayColor: Colors.white.withOpacity(0.2),
                valueIndicatorColor: Colors.white,
                valueIndicatorTextStyle: TextStyle(
                    color: theme.selectedTheme), // Inverse for readability
              ),
              child: Slider(
                value: _speed,
                min: 0.5,
                max: 5.0, // Increased max speed to 5.0
                divisions: 45, // More granular control
                label: _speed.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    _speed = value;
                  });
                  widget.onSpeedChanged(value);
                },
              ),
            ),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Close", style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: theme.selectedTheme,
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          onPressed: () {
            Navigator.pop(context);
            if (widget.isScrolling) {
              widget.onStop();
            } else {
              widget.onStart();
            }
          },
          child: Text(
            widget.isScrolling ? "Stop" : "Start",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
