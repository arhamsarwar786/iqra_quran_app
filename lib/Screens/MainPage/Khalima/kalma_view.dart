import 'package:flutter/material.dart';
import 'package:iqra/Utils/constants.dart';
import '../../../Models/khalimas_model.dart';
import '../../../Provider/theme_provider.dart';
import 'widgets.dart';

class KhalimaView extends StatelessWidget {
  final KhalimasModel khalima;
  final ThemeProvider bloc;
  KhalimaView(this.khalima, this.bloc);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: bloc.selectedSecondary,
      extendBody: true,
      appBar: AppBar(
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
              Navigator.pop(context);
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
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: kElevationToShadow[4],
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: size.height,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                     const SizedBox(
                        height: 30,
                      ),
                      Text(
                        khalima.arabic!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: MyColors.whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Text(
                        khalima.translation!,
                        textAlign: TextAlign.center,
                        // maxLines: 3,
                        style: TextStyle(
                          color: MyColors.whiteColor,
                          // fontSize: 20,

                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      const SizedBox(
                        height: 30,
                      ),
                    ],
                  ),
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
}
