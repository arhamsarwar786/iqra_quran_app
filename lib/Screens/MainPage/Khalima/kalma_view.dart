import 'package:flutter/material.dart';
import 'package:iqra/Screens/MainPage/Drawer/setting_screen.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/widgets.dart';
import 'package:provider/provider.dart';
import '../../../Models/khalimas_model.dart';
import '../../../Provider/theme_provider.dart';
import 'widgets.dart';

class KhalimaView extends StatelessWidget {
  final KhalimasModel khalima;
  KhalimaView(this.khalima);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Builder(
      builder: (context) {
         var bloc = context.watch<ThemeProvider>();
        return Scaffold(
          backgroundColor: bloc.selectedSecondary,
          extendBody: true,
          appBar: AppBar(
            actions: [
              IconButton(onPressed: (){
                push(context, SettingScreen());
              }, icon: const Icon(Icons.settings),),
            ],
            backgroundColor: bloc.selectedTheme,
            title: Text(
              khalima.title!,
              style:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
            ),
            centerTitle: true,
            elevation: 0,
            leading: IconButton(
                onPressed: () {
                  pop(context);
                },
                icon: const Icon(Icons.arrow_back)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: size.width,
                  // height: size.height,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    boxShadow: kElevationToShadow[4],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SizedBox(                      
                    // height: size.height,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                       const SizedBox(
                          height: 30,
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(children: [
                          
                            Text(
                              khalima.arabic!,                          
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                height: 1.5,
                                fontFamily: bloc.arabicFontFamily,
                                color: MyColors.whiteColor,
                                fontSize: bloc.arabicFontSize,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(
                              height: 40,
                            ),
                            Text(
                              khalima.translation!,
                              textAlign: TextAlign.center,
                              // maxLines: 3,
                              style: TextStyle(
                                fontFamily: bloc.urduFontFamily,
                                color: MyColors.whiteColor,
                                fontSize: bloc.urduFontSize,
                          
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            ],),
                          ),
                        ),
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ),
                CustomBorders(
                  image: "ktopleft.png",
                  top: 10,
                  left: 10,
                ),
                CustomBorders(
                  image: "ktopright.png",
                  top: 10,
                  right: 10,
                ),
                CustomBorders(
                  image: "kbottomleft.png",
                  bottom: 10,
                  left: 10,
                ),
                CustomBorders(
                  image: "kbottomright.png",
                  bottom: 10,
                  right: 10,
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}
