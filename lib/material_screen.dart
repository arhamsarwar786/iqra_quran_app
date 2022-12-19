import 'package:flutter/material.dart';
import 'package:iqra/splash_screen.dart';
import 'package:provider/provider.dart';

import 'Provider/theme_provider.dart';

class MaterialScreen extends StatefulWidget {
  const MaterialScreen({super.key});

  @override
  State<MaterialScreen> createState() => _MaterialScreenState();
}

class _MaterialScreenState extends State<MaterialScreen> {

  
 

  @override
  Widget build(BuildContext context) {
      Provider.of<ThemeProvider>(context).getSelectedTheme();
    return  MaterialApp(
        theme: ThemeData(
          // primarySwatch: MaterialColor(myColor.value, {myColor.value:myColor}),
          primaryColor: Provider.of<ThemeProvider>(context).selectedTheme,
          // colorScheme: ColorScheme.fromSwatch().copyWith(
          //   primary: myColor       
          //      ),
          // colorScheme: ColorScheme.fromSwatch().copyWith(
          //   // primary: primayColor,
          //   primary: myColor
          //   // secondary: secondaryColor
          // ),
          // primarySwatch: ,
          fontFamily: 'kgf',
        ),
        // onGenerateRoute: _appRoutes.onGeneratedRoute,
        home: SplashScreen(),
      );
  }
}