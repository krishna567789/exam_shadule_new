import 'package:exam_shadule_new/controller/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/session_setup_screen.dart';
import 'utils/app_theme.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Persistent Storages
  await NotificationService().init();
  await Hive.initFlutter();
  await Hive.openBox('candidates_box');
  
  // 2. Register StorageService FIRST so it can be found by others
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);
  
  // 3. Register ApiService
  Get.put(ApiService(), permanent: true);
  Get.put(DownloadController());
  
  // 4. Check login state
  bool isLoggedIn = StorageService.to.isLoggedIn();

  runApp(SecureExamApp(isLoggedIn: isLoggedIn));
}

class SecureExamApp extends StatelessWidget {
  final bool isLoggedIn;
  const SecureExamApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Secure Exam Operator Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, 
      home: isLoggedIn ? const SessionSetupScreen() : const LoginScreen(),
    );
  }
}
