import 'package:flutter/material.dart';
import 'package:iqra/Utils/constants.dart';
import '../../../Models/khalimas_model.dart';
import 'widgets.dart';

class KhalimaView extends StatelessWidget {
  final KhalimasModel khalima;
  KhalimaView(this.khalima);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.secondary,
      extendBody: true,
      appBar: AppBar(
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
      body: 
              SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      alignment: Alignment.center,
                      width: size.width,
                      height: size.height,
                      padding: const EdgeInsets.symmetric(horizontal: 30),                    
                      child: Stack(
                        children: [
                          Container(
                            width: size.width,
                            padding: EdgeInsets.all(10),
                            // constraints:,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              boxShadow: kElevationToShadow[4],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
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
                              const  SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  khalima.translation!,
                                  textAlign: TextAlign.center,
                                  // maxLines: 3,
                                  style: TextStyle(
                                    color:MyColors. whiteColor,
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
                  ],
                ),
              ),
          
          
        
      
    );
  }
}