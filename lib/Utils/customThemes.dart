
// import 'package:iqra/Helper/preference/saved_preferences.dart';
// import 'package:iqra/Utils/constants.dart';
// import 'package:iqra/Utils/utils.dart';
// import 'package:iqra/controller/methods.dart';

// getCustomTheme()async{
//   var theme = await SavedPrefernces.getTheme();
//   print("tsing");
//   print(theme.runtimeType);
  
//   if(theme == null){
//    await SavedPrefernces.setTheme(themeList[0]);
//     primayColor = themeList[0]['primary']!.toColor();
//     secondaryColor = themeList[0]['secondary']!.toColor();
//   }else{
//     print(theme['primary'].toString().toColor());
//     print(theme['secondary'].toString());
//     primayColor = theme['primary'].toString().toColor();
//     secondaryColor = theme['secondary'].toString().toColor();
//   }
// }




import 'package:flutter/material.dart';

class MyTextStyle{

  static TextStyle heading1 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 25,
  );

  static TextStyle heading2 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 20,
  );

  static TextStyle heading3 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 15,
  );

  static TextStyle heading4 = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 12,
  );
}