import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Provider/form_validate.dart';
import 'package:iqra/Provider/tasbih_count.dart';
import 'package:iqra/Provider/theme_provider.dart';
import 'package:iqra/demo.dart';
import 'package:iqra/material_screen.dart';
import 'package:provider/provider.dart';
import 'Helper/tasbih_helper.dart';
import 'Provider/main_provider.dart';

late ObjectBox objectbox;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.init();
  // await getCustomTheme();
    SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp]
     )
        .then((_) {
          runApp(MyApp());
        });
    }

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // GeneratedRoutes _appRoutes = GeneratedRoutes();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MyProvider()),
        ChangeNotifierProvider(create: ((context) => TasbeeCount())),
        ChangeNotifierProvider(create: ((context) => FormValidate())),
        ChangeNotifierProvider(create: ((context) => ThemeProvider())),
      ],
      // child: const Demo(),
      child: const MaterialScreen(),
    );
  }
}
