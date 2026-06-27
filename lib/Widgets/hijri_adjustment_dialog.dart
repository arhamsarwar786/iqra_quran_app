import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iqra/Provider/theme_provider.dart';

Future<void> showHijriAdjustmentDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Islamic Calendar Adjustment'),
        content: Consumer<ThemeProvider>(
          builder: (context, bloc, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    children: [
                      const TextSpan(text: 'Current Mode: '),
                      TextSpan(
                        text: bloc.isHijriManual
                            ? 'Manual Override'
                            : 'Auto-Detected',
                        style: TextStyle(
                          color: bloc.selectedTheme,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: bloc.hijriOffset > -5
                          ? () => bloc.changeHijriOffset(bloc.hijriOffset - 1)
                          : null,
                      color: bloc.selectedTheme,
                    ),
                    Column(
                      children: [
                        Text(
                          bloc.hijriOffset == 0 && !bloc.isHijriManual
                              ? 'Global Standard'
                              : '${bloc.hijriOffset > 0 ? '+' : ''}${bloc.hijriOffset} Day${bloc.hijriOffset.abs() > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: bloc.selectedTheme,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bloc.isHijriManual
                              ? 'Manual Calibration'
                              : 'Regional Sync',
                          style:
                              const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: bloc.hijriOffset < 5
                          ? () => bloc.changeHijriOffset(bloc.hijriOffset + 1)
                          : null,
                      color: bloc.selectedTheme,
                    ),
                  ],
                ),
                if (bloc.isHijriManual)
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        await bloc.resetHijriToAuto();
                      },
                      child: const Text('Reset to Auto Location'),
                    ),
                  ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      );
    },
  );
}
