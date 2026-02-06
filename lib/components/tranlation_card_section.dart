import "package:flutter/material.dart";
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/customThemes.dart';

import 'package:iqra/Utils/share_verse.dart';

import '../Provider/theme_provider.dart';
import '../Screens/MainPage/Khalima/widgets.dart';

class TranlationCardSection extends StatelessWidget {
  final ThemeProvider? provider;
  final urdu, arabic;
  final String? surahName;
  final String? ayatNumber;
  final String? paraNumber;
  final String? surahNumber;
  const TranlationCardSection(
      {super.key,
      this.provider,
      this.arabic,
      this.urdu,
      this.surahName,
      this.ayatNumber,
      this.paraNumber,
      this.surahNumber});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Card(
      child: SizedBox(
        width: size.width,
        child: Stack(alignment: Alignment.center, children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 50, horizontal: 20),
            alignment: Alignment.center,
            constraints: const BoxConstraints(minHeight: 250),
            color: MyColors.whiteColor,
            width: size.width,
            child: Column(
              children: [
                Text(
                  "$arabic",
                  style: MyTextStyle.heading3.copyWith(
                      fontSize: provider!.arabicFontSize,
                      fontFamily: provider!.arabicFontFamily),
                  textDirection: TextDirection.rtl,
                ),
                const Text("ترجمہ: کنزالایمان"),
                Text("$urdu",
                    style: MyTextStyle.heading3.copyWith(
                        fontSize: provider!.urduFontSize,
                        fontFamily: provider!.urduFontFamily),
                    textDirection: TextDirection.rtl),
              ],
            ),
          ),
          CustomBorders(
            color: provider!.selectedTheme,
            image: "ktopright.png",
            top: 5,
            right: 5,
          ),
          CustomBorders(
            color: provider!.selectedTheme,
            image: "kbottomleft.png",
            bottom: 5,
            left: 5,
          ),
          Positioned(
              top: 5,
              left: 5,
              child: IconButton(
                onPressed: () {
                  AppShare.image(
                    context: context,
                    bloc: provider!,
                    title: surahName ?? "Surah",
                    paraNumber: paraNumber,
                    surahNumber: surahNumber,
                    ayatNumber: ayatNumber,
                    arabicText: arabic.toString(),
                    translationText: urdu.toString(),
                    translatorName: "ترجمہ: کنزالایمان",
                  );
                  // myShare(text: "$arabic\n\n$urdu");
                },
                icon: Icon(
                  Icons.share,
                  size: 30,
                  color: provider!.selectedTheme,
                ),
              )),
        ]),
      ),
    );
  }
}
