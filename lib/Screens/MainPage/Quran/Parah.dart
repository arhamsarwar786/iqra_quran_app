import 'package:flutter/material.dart';
import 'package:iqra/Provider/quran_data_provider.dart';
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
  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      var bloc = context.read<ThemeProvider>();
      return Padding(
        padding:
            const EdgeInsets.only(left: 8.0, right: 8.0, top: 15, bottom: 10),
        child: Consumer<QuranDataProvider>(
          builder: (context, quranProvider, child) {
            if (quranProvider.isLoading || !quranProvider.isLoaded) {
              return Center(
                  child: CircularProgressIndicator(color: bloc.selectedTheme));
            }

            // Use para metadata from provider
            var paraMetadata = quranProvider.paraMetadata;

            return GridView.builder(
              itemCount: paraMetadata.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2 / 2,
                mainAxisSpacing: 20,
              ),
              itemBuilder: (context, index) {
                var paraItem = paraMetadata[index];
                int paraNumber = paraItem.paraId ?? 0;
                int ayatCount =
                    quranProvider.paraAyatCounts[paraNumber.toString()] ?? 0;
                String paraName = paraItem.paraName ?? 'Para $paraNumber';

                return InkWell(
                  onTap: () {
                    push(
                        context,
                        ParaArabicScreen(
                          para: null,
                          ayatInPara: ayatCount,
                          parahCount: paraNumber.toString(),
                          parahname: paraName,
                        ));
                  },
                  child: Card(
                    elevation: 5,
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
                                    const EdgeInsets.only(left: 8.0, top: 2),
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: bloc.selectedTheme,
                                  child: Center(
                                      child: Text(
                                    (index + 1).toString(),
                                    style: const TextStyle(color: Colors.white),
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
                                      fontFamily: bloc.arabicFontFamily,
                                      color: Colors.black,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w500),
                                ),
                              )
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
