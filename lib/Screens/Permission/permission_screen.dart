import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iqra/Screens/MainPage/main_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../widgets.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool _locationGranted = false;
  bool _notificationGranted = false;
  bool _audioGranted = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    final locationStatus = await Permission.location.status;
    final notificationStatus = await Permission.notification.status;
    final audioStatus = await Permission.microphone.status;

    if (mounted) {
      setState(() {
        _locationGranted = locationStatus.isGranted;
        _notificationGranted = notificationStatus.isGranted;
        _audioGranted = audioStatus.isGranted;
      });
    }
  }

  Future<void> _checkAutoNavigate() async {
    if (_locationGranted && _notificationGranted && _audioGranted) {
      if (mounted) {
        pushUntil(context, const MainScreen());
      }
    }
  }

  Future<void> _requestLocation() async {
    if (_locationGranted) return;
    final status = await Permission.location.request();
    if (mounted) {
      setState(() => _locationGranted = status.isGranted);
      if (status.isPermanentlyDenied) {
        _showSettingsDialog("Location");
      } else {
        _checkAutoNavigate();
      }
    }
  }

  Future<void> _requestNotification() async {
    if (_notificationGranted) return;
    final status = await Permission.notification.request();
    if (mounted) {
      setState(() => _notificationGranted = status.isGranted);
      if (status.isPermanentlyDenied) {
        _showSettingsDialog("Notification");
      } else {
        _checkAutoNavigate();
      }
    }
  }

  Future<void> _requestMicrophone() async {
    if (_audioGranted) return;
    final status = await Permission.microphone.request();
    if (mounted) {
      setState(() => _audioGranted = status.isGranted);
      if (status.isPermanentlyDenied) {
        _showSettingsDialog("Microphone");
      } else {
        _checkAutoNavigate();
      }
    }
  }

  void _showSettingsDialog(String permissionName) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('$permissionName Permission Required'),
        content: Text(
            'This app needs $permissionName permission to function correctly. Please enable it in the app settings.'),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Open Settings'),
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }

  void _handleGetStarted() {
    if (_locationGranted && _notificationGranted && _audioGranted) {
      pushUntil(context, const MainScreen());
    } else {
      snackBar(context, "Please allow all permissions to continue.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xff0E323F),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xff0E323F),
        body: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset(
                  'assets/images/logo.png',
                  height: 100,
                  width: 100,
                ),
                const SizedBox(height: 30),
                const Text(
                  "Welcome to IQRA QURAN",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "To provide you with the best experience, please allow the following permissions.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xff9B9B9B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 50),
                _buildPermissionItem(
                  icon: Icons.location_on_rounded,
                  title: "Location Access",
                  description:
                      "Needed for accurate Prayer Times and Qibla direction.",
                  isGranted: _locationGranted,
                  onTap: _requestLocation,
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  icon: Icons.notifications_active_rounded,
                  title: "Notifications",
                  description:
                      "Receive alerts for Prayer Times and daily verses.",
                  isGranted: _notificationGranted,
                  onTap: _requestNotification,
                ),
                const SizedBox(height: 20),
                _buildPermissionItem(
                  icon: Icons.mic_rounded,
                  title: "Microphone Access",
                  description: "Use voice search and speech-to-text features.",
                  isGranted: _audioGranted,
                  onTap: _requestMicrophone,
                ),
                const Spacer(),
                if (_locationGranted && _notificationGranted && _audioGranted)
                  GestureDetector(
                    onTap: _handleGetStarted,
                    child: Container(
                      height: 55,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        "GET STARTED",
                        style: TextStyle(
                          color: Color(0xff0E323F),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    height: 55,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: const Text(
                      "Tap the tiles above to allow access",
                      style: TextStyle(
                        color: Color(0xff9B9B9B),
                        fontSize: 14,
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isGranted
                ? Colors.green.withOpacity(0.5)
                : Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isGranted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isGranted ? Colors.green : Colors.white70,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      color: Color(0xff9B9B9B),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isGranted)
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 24,
              )
            else
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white54,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
