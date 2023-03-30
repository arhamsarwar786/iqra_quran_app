import "package:flutter/material.dart";
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/Utils/customThemes.dart';

import '../Provider/theme_provider.dart';
import '../Screens/MainPage/Khalima/widgets.dart';

class TranlationCardSection extends StatelessWidget {
  final ThemeProvider? provider;
  final urdu,arabic;
  const TranlationCardSection({super.key,this.provider,this.arabic,this.urdu});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Card(
      child: Container(
        width: size.width,
        child: Stack(
          alignment: Alignment.center, children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 50,horizontal: 20),
            alignment: Alignment.center,
            constraints: BoxConstraints(minHeight: 250),
            color: MyColors.whiteColor,
            width: size.width,
            child: Column(
              children: [
                Text("${arabic}",style: MyTextStyle.heading3.copyWith(fontSize: provider!.arabicFontSize,fontFamily: provider!.arabicFontFamily),textDirection: TextDirection.rtl,),
                Text("${urdu}",style: MyTextStyle.heading3.copyWith(fontSize: provider!.urduFontSize,fontFamily: provider!.urduFontFamily),textDirection: TextDirection.rtl),
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
            child: IconButton(onPressed: (){}, icon: Icon(Icons.share,size: 30,color: provider!.selectedTheme,),)),
        ]),
      ),
    );
  }
}
