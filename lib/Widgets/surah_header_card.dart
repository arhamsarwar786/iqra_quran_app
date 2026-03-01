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
      decoration: BoxDecoration(
        color: theme.selectedTheme,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    fontSize: 16,
                    fontFamily: theme.arabicFontFamily,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  metadata.ayas,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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
                      // Left Group: Order & Type
                      // Right Group (via RTL): Name & Index

                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            metadata.order,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "(${metadata.type == 'Meccan' ? 'مكية' : 'مدنية'})",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            metadata.name,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: theme.arabicFontFamily,
                            ),
                          ),
                        ],
                      ),

                      // Left Group (via RTL): Type & Order
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 2.0),
                  child: Divider(
                      color: Colors.white54,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "بِسْمِ اللهِ الرَّحْمٰنِ الرَّحِيْمِ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
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
                    fontSize: 18,
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
