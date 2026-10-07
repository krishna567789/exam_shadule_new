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
import 'controller/device_info_controller.dart';
import 'verifier/services/api_service.dart';
import 'verifier/services/storage_service.dart';
import 'verifier/services/sync_service.dart';
import 'verifier/controller/session_controller.dart';
import 'verifier/controller/login_controller.dart';
import 'verifier/controller/dashboard_controller.dart';
import 'verifier/controller/candidates_controller.dart';
import 'verifier/screens/dashboard_screen.dart';
import 'verifier/screens/verifier_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Persistent Storages
  await NotificationService().init();
  await Hive.initFlutter();
  await Hive.openBox('candidates_box');
  final vsePendingBox = await Hive.openBox('vse_pending_sync_box');

  // 2. Register StorageService FIRST so it can be found by others
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService, permanent: true);

  // 3. Register ApiService
  Get.put(ApiService(), permanent: true);
  Get.put(DownloadController());

  // 4. Register the verifier console module (separate storage/API stack).
  final vseStorage = VerifierStorageService();
  await vseStorage.init();
  Get.put(vseStorage, permanent: true);
  Get.put(VerifierApiService(), permanent: true);
  final vseSync = VerifierSyncService();
  await vseSync.init(vsePendingBox);
  Get.put(vseSync, permanent: true);
  Get.put(VerifierSessionController(), permanent: true);
  Get.put(VerifierLoginController(), permanent: true);
  Get.put(VerifierDashboardController(), permanent: true);
  Get.put(VerifierCandidatesController(), permanent: true);
  Get.put(DeviceInfoController(), permanent: true);

  // 5. Check login state — operator session wins; else verifier session.
  bool isLoggedIn = StorageService.to.isLoggedIn();
  bool vseLoggedIn = VerifierStorageService.to.isLoggedIn();
  bool vseProfileDone =
      VerifierStorageService.to.getBool(VerifierStorageService.keyIsProfileCompleted) ??
          false;

  Widget home;
  if (isLoggedIn) {
    home = const SessionSetupScreen();
  } else if (vseLoggedIn) {
    home = vseProfileDone
        ? const VerifierDashboardScreen()
        : const VerifierProfileScreen();
  } else {
    home = const LoginScreen();
  }

  runApp(SecureExamApp(home: home));
}

class SecureExamApp extends StatelessWidget {
  final Widget home;
  const SecureExamApp({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Secure Exam Console',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: home,
    );
  }
}
