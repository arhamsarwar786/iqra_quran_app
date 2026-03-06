import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final primaryMaterialColor =
        ThemeProvider.createMaterialColor(themeProvider.selectedTheme);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: themeProvider.selectedTheme,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: themeProvider.selectedSecondary,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3:
              true, // Switched to Material 3 for better visuals with Poppins
          primarySwatch: primaryMaterialColor,
          primaryColor: themeProvider.selectedTheme,
          scaffoldBackgroundColor: themeProvider.selectedSecondary,
          canvasColor: themeProvider.selectedSecondary,
          highlightColor: themeProvider.selectedTheme.withOpacity(0.1),
          splashColor: themeProvider.selectedTheme.withOpacity(0.1),
          fontFamily: 'Poppins', // Using the bundled Poppins font
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: primaryMaterialColor,
          ).copyWith(
            primary: themeProvider.selectedTheme,
            secondary: themeProvider.selectedTheme,
            background: themeProvider.selectedSecondary,
            surface: themeProvider.selectedSecondary,
          ),
          appBarTheme: AppBarTheme(
            backgroundColor: themeProvider.selectedTheme,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
            ),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}
