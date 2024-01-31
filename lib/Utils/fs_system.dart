


import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;


import 'dart:convert';
import 'dart:io';

addIndex(context)async{
   final filePath = '/Users/arhamsarwar/Documents/GitHub/iqra_quran_app/assets/extraction/quran-devsinn.json';

  // // Read the JSON file
  // final jsonString = await rootBundle.loadString(filePath);
  // final Map<String, dynamic> data = json.decode(jsonString);
  var d = await DefaultAssetBundle.of(context)
                  .loadString("assets/extraction/quran-devsinn.json");

                  var data  = jsonDecode(d.toString());

  // Add index to each element in the "aya" array
  final List<dynamic> surahList = data['sura'];
  for (int i = 0; i < surahList.length; i++) {
    for (var j = 0; j < surahList[i]["aya"].length; j++) {
      if(i == 8){
    surahList[i]["aya"][j]['ayatNumber'] = j + 1;

      }else{
    surahList[i]["aya"][j]['ayatNumber'] = j;

      }
      
    }
  }
 final updatedJsonString = json.encode(data);
 print(updatedJsonString);

  // Write the modified data back to the same file
  final file = File(filePath);
  await file.writeAsString(updatedJsonString);

  print('Index added and file updated successfully.');
}