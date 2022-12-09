import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Models/quran_kareem_urdu_model.dart';

class MyProvider extends ChangeNotifier{
  List<QuranKareemUrduModel>? transQuran;
  int screenIndex = 0;
  

  loadQuran()async{
   var data =   await rootBundle.loadString("assets/quran_kareem/urdu_translation/quran_urdu.json");
      transQuran =  quranKareemUrduModelFromJson(data);

  print(transQuran);
   notifyListeners();
  }


  QuranKareemUrduModel fetchTransSurat(){
    loadQuran();
    return transQuran![0];

  }
}
