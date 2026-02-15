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

            return GridView.builder(
              itemCount: surahMetadata.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1, // 2/2 is 1
                mainAxisSpacing: 20,
                crossAxisSpacing: 10,
              ),
              padding: const EdgeInsets.only(bottom: 20),
              itemBuilder: (context, index) {
                var surah = surahMetadata[index];
                int surahNumber = int.tryParse(surah.index) ?? (index + 1);

                return InkWell(
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
                  child: Card(
                    color: themeProvider.selectedSecondary,
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.22,
                      width: MediaQuery.of(context).size.height * 0.22,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.only(left: 8.0, top: 4),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: themeProvider.selectedTheme,
                                  child: Center(
                                      child: Text(
                                    surah.index,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 10),
                                  )),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(right: 8.0, top: 4),
                                child: Text(
                                  surah.type == 'Meccan' ? 'مكية' : 'مدنية',
                                  style: TextStyle(
                                    fontFamily: themeProvider.arabicFontFamily,
                                    color: Colors.grey[700],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              FittedBox(
                                child: Text(
                                  surah.name,
                                  style: TextStyle(
                                      fontFamily:
                                          themeProvider.arabicFontFamily,
                                      color: Colors.black,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                              Text(
                                surah.ename,
                                style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Ayat: ${surah.ayas}",
                                    style: TextStyle(
                                        fontFamily:
                                            themeProvider.arabicFontFamily,
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Ruku: ${surah.rukus}",
                                    style: TextStyle(
                                        fontFamily:
                                            themeProvider.arabicFontFamily,
                                        color: Colors.black,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  )
                                ],
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                height: 40,
                                width: 40,
                                decoration: const BoxDecoration(
                                    image: DecorationImage(
                                        image: AssetImage(
                                            "assets/images/cornerbottom.png"),
                                        fit: BoxFit.fill)),
                              ),
                              Container(
                                height: 25,
                                width: 25,
                                margin:
                                    const EdgeInsets.only(right: 4, bottom: 4),
                                decoration: const BoxDecoration(
                                  image: DecorationImage(
                                    image:
                                        AssetImage("assets/images/icons2.png"),
                                  ),
                                ),
                              ),
                            ],
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
