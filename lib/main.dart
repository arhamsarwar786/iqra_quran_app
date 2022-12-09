import 'package:flutter/material.dart';
import 'package:iqra/Provider/form_validate.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Utils/constants.dart';
import 'package:iqra/splash_screen.dart';
import 'package:provider/provider.dart';
import 'Helper/tasbih_helper.dart';
import 'Provider/main_provider.dart';
import 'Screens/MainPage/main_screen.dart';

late ObjectBox objectbox;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // GeneratedRoutes _appRoutes = GeneratedRoutes();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (BuildContext context) => MyProvider()),
        ChangeNotifierProvider(create: ((context) => TasbeeCount())),
        ChangeNotifierProvider(create: ((context) => FormValidate())),
      ],
      child: MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSwatch().copyWith(
            primary: primayColor,
          ),
          // primarySwatch: ,
          fontFamily: 'kgf',
        ),
        // onGenerateRoute: _appRoutes.onGeneratedRoute,
        home: SplashScreen(),
      ),
    );
  }
}
