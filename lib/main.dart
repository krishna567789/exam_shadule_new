import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/session_setup_screen.dart';
import 'screens/operator_profile_screen.dart';
import 'utils/app_theme.dart';

import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await Hive.initFlutter();
  await Hive.openBox('candidates_box');
  
  SharedPreferences prefs = await SharedPreferences.getInstance();
  bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
  String? token = prefs.getString('token');

  runApp(SecureExamApp(isLoggedIn: isLoggedIn, hasToken: token != null));
}

class SecureExamApp extends StatelessWidget {
  final bool isLoggedIn;
  final bool hasToken;
  const SecureExamApp({super.key, required this.isLoggedIn, required this.hasToken});

  @override
  Widget build(BuildContext context) {
    Widget initialScreen;
    if (isLoggedIn) {
      initialScreen = const SessionSetupScreen();
    } else if (hasToken) {
      initialScreen = const OperatorProfileScreen();
    } else {
      initialScreen = const LoginScreen();
    }

    return GetMaterialApp(
      title: 'Secure Exam Operator Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Automatically switch based on system settings
      home: initialScreen,
    );
  }
}
