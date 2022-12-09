import 'package:flutter/material.dart';
import '../Screens/MainPage/main_screen.dart';

// class GeneratedRoutes {
//   Route? onGeneratedRoute(RouteSettings settings) {
//     switch (settings.name) {
//       case '/':
//         return MaterialPageRoute(builder: (_) => MainScreen());
//       case '/':
//         return MaterialPageRoute(builder: (_) => MainScreen());
        
//       default:
//         return null;
//     }
//   }
// }
class MyWidget extends StatelessWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(onPressed: null,
    child: Text("sing up"),
    style: ElevatedButton.styleFrom(
      primary: Colors.black,
    ),
    );
  }
}