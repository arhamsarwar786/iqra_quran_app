import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/Screens/MainPage/Quran/ParahView.dart';
import 'package:iqra/Screens/MainPage/Quran/para_arabic_screen.dart';
import 'package:iqra/Screens/MainPage/Quran/translation/parah_translation_screen.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';

import '../../../Models/para_model.dart';
// import 'ParahView.dart';

class Parah extends StatefulWidget {
  const Parah({Key? key}) : super(key: key);

  @override
  State<Parah> createState() => _ParahState();
}

class _ParahState extends State<Parah> {
  static const parah = [
    'آلم',
    'سَيَقُولُ	',
    'تِلْكَ ٱلْرُّسُلُ	',
    'لن تنالوا	',
    'وَٱلْمُحْصَنَاتُ	',
    'لَا يُحِبُّ ٱللهُ',
    'وَإِذَا سَمِعُوا',
    'وَلَوْ أَنَّنَا	',
    'قَالَ ٱلْمَلَأُ',
    'وَٱعْلَمُواْ	',
    'يَعْتَذِرُونَ	',
    'وَمَا مِنْ دَآبَّةٍ	',
    'وَمَا أُبَرِّئُ',
    'رُبَمَا ',
    'سُبْحَانَ ٱلَّذِى',
    'قَالَ أَلَمْ',
    'ٱقْتَرَبَ لِلْنَّاسِ',
    'قَدْ أَفْلَحَ',
    'وَقَالَ ٱلَّذِينَ',
    'أَمَّنْ خَلَقَ',
    'أُتْلُ مَاأُوْحِیَ',
    'وَمَنْ يَّقْنُتْ',
    'وَمَآ لي	',
    'فَمَنْ أَظْلَمُ',
    'إِلَيْهِ يُرَدُّ',
    'حم',
    'قَالَ فَمَا خَطْبُكُم	',
    'قَدْ سَمِعَ ٱللهُ	',
    'تَبَارَكَ ٱلَّذِى	',
    'عَمَّ',
  ];
  static const _num = [
    '148',
    '111',
    '126',
    '131',
    '124',
    '110',
    '149',
    '142',
    '159',
    '127',
    '151',
    '170',
    '154',
    '227',
    '185',
    '269',
    '190',
    '202',
    '339',
    '171',
    '178',
    '169',
    '357',
    '175',
    '246',
    '195',
    '399',
    '137',
    '431',
    '564',
  ];
  List<int> numberofayat = [];

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Padding(
          padding:
              const EdgeInsets.only(left: 8.0, right: 8.0, top: 15, bottom: 10),
          child: FutureBuilder(
              future: DefaultAssetBundle.of(context)
                  .loadString("assets/extraction/quran-devsinn-para.json"),
              builder: (context, snapshot) {
                if(snapshot.hasData){
                var data = json.decode(snapshot.data.toString());
                ParahModel parahData = ParahModel.fromJson(data);
                return GridView.builder(
                    itemCount: parahData.para!.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 2 / 2,
                      // crossAxisSpacing: 10,
                      mainAxisSpacing: 20,
                    ),
                    itemBuilder: (context, index) {
                      Para para = parahData.para![index];
                      return InkWell(
                        onTap: () {
                          push(context,
                           ParaArabicScreen(
                            para: para,
                            ayatInPara: para.totalAyat,
                                        parahCount: (index + 1).toString(),
                                        parahname: para.name,)
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
                                        para.name!,
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
              

                }

                return CircularProgressIndicator.adaptive();
                
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
