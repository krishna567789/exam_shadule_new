import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const BioSecureApp());
}

class BioSecureApp extends StatelessWidget {
  const BioSecureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BioSecure Operator Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const LoginScreen(),
    );
  }
}
