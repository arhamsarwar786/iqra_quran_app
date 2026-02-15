import 'package:flutter/material.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:provider/provider.dart';
import 'Quranview.dart';

class Surah extends StatefulWidget {
  const Surah({Key? key}) : super(key: key);

  @override
  State<Surah> createState() => _SurahState();
}

class _SurahState extends State<Surah> {
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var themeProvider = context.read<ThemeProvider>();

      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: Consumer<QuranDataProvider>(
          builder: (context, quranProvider, child) {
            if (quranProvider.isLoading || !quranProvider.isLoaded) {
              return Center(
                child: CircularProgressIndicator(
                  color: themeProvider.selectedTheme,
                ),
              );
            }

            var surahMetadata = quranProvider.surahMetadata;

            return ListView.builder(
              itemCount: surahMetadata.length,
              itemBuilder: (context, index) {
                var surah = surahMetadata[index];
                int surahNumber = int.tryParse(surah.index) ?? (index + 1);

                return Card(
                  elevation: 5,
                  margin:
                      const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: themeProvider.selectedSecondary,
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuranView(
                              suratNumber: surahNumber,
                              ayatCount: surah.ayas,
                              surahName: surah.name,
                            ),
                          ),
                        );
                      },

                      // Leading: Surah Number
                      leading: Container(
                        width: 45,
                        height: 45,
                        decoration: BoxDecoration(
                          color: themeProvider.selectedTheme,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  themeProvider.selectedTheme.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            surah.index,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      // Title: Surah Info
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // English Name
                              Expanded(
                                child: Text(
                                  surah.ename,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Surah Details Row
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              children: [
                                // Maki/Madani Icon
                                Icon(
                                  surah.type == 'Meccan'
                                      ? Icons.mosque_outlined
                                      : Icons.location_city_outlined,
                                  size: 14,
                                  color: themeProvider.selectedTheme,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  surah.type == 'Meccan' ? 'مكية' : 'مدنية',
                                  style: TextStyle(
                                    fontFamily: themeProvider.arabicFontFamily,
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Verses Count
                                Icon(
                                  Icons.format_list_numbered,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${surah.ayas} Ayat',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Ruku Count
                                Icon(
                                  Icons.bookmark_outline,
                                  size: 14,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${surah.rukus} Ruku',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Trailing: Arabic Name
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            surah.name,
                            style: TextStyle(
                              fontFamily: themeProvider.arabicFontFamily,
                              color: themeProvider.selectedTheme,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            surah.tname,
                            style: TextStyle(
                              fontFamily: themeProvider.urduFontFamily,
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
    });
  }
}
