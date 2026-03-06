import 'package:flutter/material.dart';
import 'package:iqra/Models/surah_metadata_model.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';

class SurahHeaderCard extends StatelessWidget {
  final SurahMetadata metadata;
  const SurahHeaderCard({super.key, required this.metadata});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

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
                    padding: const EdgeInsets.only(bottom: 4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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

/// A unified header widget that handles both the white title bar and the red surah card.
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

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          // 1. The Pinned Red Surah Header Card (Pinned at the bottom of the SliverAppBar)
          if (metadata != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 100,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: SurahHeaderCard(
                  key: ValueKey(metadata!.index),
                  metadata: metadata!,
                ),
              ),
            ),

          // 2. The Collapsible White Bar (Title, Background, and Back Button)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 56,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isScrollingDown ? 0.0 : 1.0,
              child: Container(
                color: Colors.white,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Centered Title
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: theme.arabicFontFamily,
                      ),
                    ),
                    // Back Button (aligned left)
                    Positioned(
                      left: 0,
                      child: IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
