import 'dart:convert';

import "package:flutter/material.dart";

class Demo extends StatelessWidget {
  const Demo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: DefaultAssetBundle.of(context).loadString(
                  "assets/quran_kareem/urdu_translation/final_quran.json"),
        builder: (context,AsyncSnapshot snapshot) {
          print(snapshot.data);
          var data = jsonDecode(snapshot.data);
          
          if (!snapshot.hasData) {
              return CircularProgressIndicator();
          }
          // print(snapshot.data[0]['aya'].toString() + "arham");

          return ListView.builder(
            itemCount: data[1]["aya"].length,
            itemBuilder: (context,index){
            return  ListTile(
              title: Text(
                "${data[1]["aya"][index]['arabic']}",textAlign: TextAlign.right,style: TextStyle(fontSize: 30,fontFamily: "pdmsSaleem"),
              ), subtitle: Text(
                "${data[1]["aya"][index]['urdu']}",textAlign: TextAlign.right,style: TextStyle(fontSize: 30,fontFamily: "lateef"),
              ),
            );
          });
        }
      ),
    );
  }
}