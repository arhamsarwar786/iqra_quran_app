import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';

class Parah extends StatefulWidget {
  const Parah({Key? key}) : super(key: key);

  @override
  State<Parah> createState() => _ParahState();
}

class _ParahState extends State<Parah> {
  static const parahNames = [
    'آلم',
    'سَيَقُولُ',
    'تِلْكَ ٱلْرُّسُلُ',
    'لن تنالوا',
    'وَٱلْمُحْصَنَاتُ',
    'لَا يُحِبُّ ٱللهُ',
    'وَإِذَا سَمِعُوا',
    'وَلَوْ أَنَّنَا',
    'قَالَ ٱلْمَلَأُ',
    'وَٱعْلَمُواْ',
    'يَعْتَذِرُونَ',
    'وَمَا مِنْ دَآبَّةٍ',
    'وَمَا أُبَرِّئُ',
    'رُبَمَا',
    'سُبْحَانَ ٱلَّذِى',
    'قَالَ أَلَمْ',
    'ٱقْتَرَبَ لِلْنَّاسِ',
    'قَدْ أَفْلَحَ',
    'وَقَالَ ٱلَّذِينَ',
    'أَمَّنْ خَلَقَ',
    'أُتْلُ مَاأُوْحِیَ',
    'وَمَنْ يَّقْنُتْ',
    'وَمَآ لي',
    'فَمَنْ أَظْلَمُ',
    'إِلَيْهِ يُرَدُّ',
    'حم',
    'قَالَ فَمَا خَطْبُكُم',
    'قَدْ سَمِعَ ٱللهُ',
    'تَبَارَكَ ٱلَّذِى',
    'عَمَّ',
  ];

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Padding(
          padding:
              const EdgeInsets.only(left: 8.0, right: 8.0, top: 15, bottom: 10),
          child: FutureBuilder(
              future: DefaultAssetBundle.of(context)
                  .loadString("assets/extraction/quran2026.json"),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: bloc.selectedTheme));
                }

                // Parse the JSON and group by paraId
                final quranData = json.decode(snapshot.data.toString()) as List;
                Map<String, List<Map<String, dynamic>>> paraGroups = {};
                
                for (var item in quranData) {
                  String paraId = item["paraId"]?.toString() ?? "0";
                  if (!paraGroups.containsKey(paraId)) {
                    paraGroups[paraId] = [];
                  }
                  paraGroups[paraId]!.add(item);
                }

                // Get sorted para numbers (1-30)
                List<int> paraNumbers = paraGroups.keys
                    .map((k) => int.tryParse(k) ?? 0)
                    .where((n) => n > 0)
                    .toList()
                  ..sort();

                return GridView.builder(
                    itemCount: paraNumbers.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2 / 2,
                      mainAxisSpacing: 20,
                    ),
                    itemBuilder: (context, index) {
                      int paraNumber = paraNumbers[index];
                      int ayatCount = paraGroups[paraNumber.toString()]!.length;
                      String paraName = index < parahNames.length 
                          ? parahNames[index] 
                          : 'Para $paraNumber';

                      return InkWell(
                        onTap: () {
                          push(context,
                           ParaArabicScreen(
                            para: null,
                            ayatInPara: ayatCount,
                                        parahCount: paraNumber.toString(),
                                        parahname: paraName,)
                                        );
                          // Navigator.push(
                          //     context,
                          //     MaterialPageRoute(
                          //         builder: (context) => PQuranView(
                          //               ayatInSura: numberofayat,
                          //               parahCount: (index + 1).toString(),
                          //               parahname: parah[index].toString(),
                          //             )));
                        },
                        child: Card(
                          elevation: 5,
                          child: Container(
                            height: MediaQuery.of(context).size.height * 0.22,
                            width: MediaQuery.of(context).size.height * 0.22,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          left: 8.0, top: 2),
                                      child: CircleAvatar(
                                        radius: 12,
                                        backgroundColor: bloc.selectedTheme,
                                        child: Center(
                                            child: Text(
                                          (index + 1).toString(),
                                          style: TextStyle(color: Colors.white),
                                        )),
                                      ),
                                    ),
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: const BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  "assets/images/cornertop.png"),
                                              fit: BoxFit.fill)),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    FittedBox(
                                      child: Text(
                                        paraName,
                                        style: TextStyle(
                                            fontFamily: bloc.urduFontFamily,
                                            color: Colors.black,
                                            fontSize: 30,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    )
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      height: 50,
                                      width: 50,
                                      decoration: const BoxDecoration(
                                          image: DecorationImage(
                                              image: AssetImage(
                                                  "assets/images/cornerbottom.png"),
                                              fit: BoxFit.fill)),
                                    ),
                                    Container(
                                      height: 25,
                                      width: 25,
                                      decoration: const BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                              "assets/images/icons2.png"),
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
                    });
              }));
    });
  }
}

// quran.juzs.juz[0].aya

// ,
//           {
//             "isPart": true,
//             "Surat": 2,
//             "Place":"الربع",
//             "arabic": null,
//             "translation1": null,
//             "translation2": null,
//             "ayatNumber": null
//           },
