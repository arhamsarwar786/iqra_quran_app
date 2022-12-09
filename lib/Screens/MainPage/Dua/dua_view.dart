import 'package:flutter/material.dart';
import 'package:iqra/Utils/constants.dart';

class DuaView extends StatelessWidget {
  final arabic , urdu;
  DuaView({this.arabic,this.urdu});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text("Dua"),
        centerTitle: true,      
      ),
      body: SingleChildScrollView(
        child: Container(
            alignment: Alignment.center,
                      width: size.width,
                      height: size.height - 50,
          child: Stack(
                alignment: Alignment.center,
            children: [
              Container(
                // alignment: Alignment.center,
                padding: EdgeInsets.all(20),
                margin: EdgeInsets.all(10),
                 decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(color: greyColor,blurRadius: 5)
                          ],
                          // border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(10)
                        ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                  Text(arabic, textDirection: TextDirection.rtl,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 30,locale: Locale('ur') ,),),
                  Text(urdu,style: TextStyle(fontWeight: FontWeight.w400,fontSize: 20), textDirection: TextDirection.rtl,),
                ],),
              ),
            ],
          ),
        ),
      ),
    );
  }
}