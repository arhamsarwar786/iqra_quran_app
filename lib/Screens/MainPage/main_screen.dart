import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Provider/main_provider.dart';
import '../../Provider/theme_provider.dart';
import '../../widgets.dart';
import 'package:upgrader/upgrader.dart';
import 'Dua/dua_screen.dart';
import 'Home/HomeScreen.dart';
import 'Drawer/setting_screen.dart';
import 'Quran/Favorite.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    // Start update check
    _checkUpdate();
  }

  Future<void> _checkUpdate() async {
    final theme = Provider.of<ThemeProvider>(context, listen: false);

    final upgrader = Upgrader(
      // Fetch results from store
      debugLogging: true,
      durationUntilAlertAgain: Duration.zero,
    );

    await upgrader.initialize();

    if (upgrader.shouldDisplayUpgrade()) {
      _showCustomUpdateDialog(
          context, theme, upgrader.currentAppStoreVersion ?? "1.1.0");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force unfocus to ensure keyboard is never open on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false, // Prevent keyboard from shifting UI
        body: Consumer<MyProvider>(builder: (context, provider, child) {
          return const Home();
        }),
      ),
    );
  }

  void _showCustomUpdateDialog(
      BuildContext context, ThemeProvider theme, String newVersion) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Disable back button
          child: Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            backgroundColor: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with Mosque Icon
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: theme.selectedTheme,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    image: const DecorationImage(
                      image: AssetImage("assets/images/BgImage.png"),
                      fit: BoxFit.cover,
                      opacity: 0.2,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.system_update_rounded,
                            color: Colors.white, size: 40),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        "Update Required",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    children: [
                      const Text(
                        "A new version of IQRA QURAN is available with enhanced search and new features. Please update to continue.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 25),
                      // Version Comparison
                      Row(
                        children: [
                          _versionPill("Current", "0.0.0", Colors.grey[400]!),
                          const Expanded(
                              child: Icon(Icons.arrow_forward_rounded,
                                  color: Colors.grey, size: 16)),
                          _versionPill("New", newVersion, theme.selectedTheme),
                        ],
                      ),
                      const SizedBox(height: 35),
                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () async {
                            const url =
                                "https://play.google.com/store/apps/details?id=com.devsinntechnologies.iqraquran";
                            if (await canLaunchUrl(Uri.parse(url))) {
                              await launchUrl(Uri.parse(url),
                                  mode: LaunchMode.externalApplication);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.selectedTheme,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            elevation: 5,
                            shadowColor: theme.selectedTheme.withOpacity(0.4),
                          ),
                          child: const Text(
                            "UPDATE NOW",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _versionPill(String label, String version, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: color)),
          Text(version,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Future<bool> _onWillPop() async {
    // Check if Home drawer is open using the static key
    if (Home.scaffoldKey.currentState?.isDrawerOpen ?? false) {
      Home.scaffoldKey.currentState?.closeDrawer();
      return false;
    }

    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  if (Platform.isAndroid) {
                    SystemNavigator.pop();
                  } else if (Platform.isIOS) {
                    exit(0);
                  }
                },
                child: MaterialButton(
                    color: Theme.of(context).primaryColor,
                    onPressed: () {
                      if (Platform.isAndroid) {
                        SystemNavigator.pop();
                      } else if (Platform.isIOS) {
                        exit(0);
                      }
                    },
                    child: const Text(
                      'Yes',
                      style: TextStyle(color: Colors.white),
                    )),
              ),
            ],
          ),
        )) ??
        false;
  }
}

////BottomApp Bar created by Abdul Wahab//////
class BottomBarApp extends StatelessWidget {
  final ThemeProvider? bloc;
  final bool isShow;
  final bool hasNotch;
  const BottomBarApp({
    super.key,
    this.bloc,
    this.isShow = true,
    this.hasNotch = true,
  });

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final myProvider = Provider.of<MyProvider>(context, listen: false);

    return BottomAppBar(
      color: bloc!.selectedSecondary,
      elevation: 0,
      shape: hasNotch
          ? const AutomaticNotchedShape(
              RoundedRectangleBorder(),
              CircleBorder(),
            )
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        height: 60,
        child: !isShow
            ? Container()
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      push(context, const Favorite());
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        Text(
                          "Favorite",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      push(context, const SettingScreen());
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        Text(
                          "Settings",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
