import 'package:flutter/material.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class SurahHeaderCard extends StatelessWidget {
  final SurahMetadata metadata;
  const SurahHeaderCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();

    return Container(
      margin: EdgeInsets.zero,
      height: 100, // Explicit height for pinned header stability
      decoration: BoxDecoration(
        color: theme.selectedTheme,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Right Section (via RTL): Ayas
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "آياتها",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: theme.arabicFontFamily,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metadata.ayas,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Divider
          const VerticalDivider(
              color: Colors.white,
              thickness: 1,
              width: 1,
              indent: 10,
              endIndent: 10),

          // Center Section: Name, Order, Type, Bismillah
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                // Surah Info Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            metadata.order,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${metadata.type == 'Meccan' ? 'مكية' : 'مدنية'})",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontFamily: theme.arabicFontFamily,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            metadata.index,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            metadata.name,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: theme.arabicFontFamily,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (metadata.index != "9")
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: const Divider(
                        color: Colors.white54,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20),
                  ),
                if (metadata.index != "9")
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 4, left: 5, right: 5),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "﷽",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          fontFamily: theme.arabicFontFamily,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Divider
          const VerticalDivider(
              color: Colors.white,
              thickness: 1,
              width: 1,
              indent: 10,
              endIndent: 10),

          // Left Section (via RTL): Rukus
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "رکوعاتها",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontFamily: theme.arabicFontFamily,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metadata.rukus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

/// Pinned teal surah header with back button (no separate white title bar).
class CompleteQuranHeader extends StatelessWidget {
  final String title;
  final SurahMetadata? metadata;
  final bool isScrollingDown;

  const CompleteQuranHeader({
    super.key,
    required this.title,
    this.metadata,
    required this.isScrollingDown,
  });

  static const double headerHeight = 100.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();

    if (metadata != null) {
      return SizedBox(
        height: headerHeight,
        width: double.infinity,
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SurahHeaderCard(
                  key: ValueKey(metadata!.index),
                  metadata: metadata!,
                ),
              ),
            ),
            // LTR back button over the teal header
            Positioned(
              top: 0,
              left: 0,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  tooltip: 'Back',
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Fallback when metadata is not ready yet
    return Container(
      height: 56,
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: theme.arabicFontFamily,
            ),
          ),
          Positioned(
            left: 0,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
