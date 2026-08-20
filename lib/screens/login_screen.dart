import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../utils/app_theme.dart';
import '../controller/login_controller.dart';
import '../widgets/custom_text.dart';
import 'finger_test_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LoginController _loginController = Get.put(LoginController());
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  bool _cameraGranted = false;
  bool _biometricGranted = false;
  bool _internetGranted = false;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  static const _platform =
      MethodChannel('com.example.exam_shadule_new/rd_service');

  @override
  void initState() {
    super.initState();
    _checkAllPermissions();
    _initLiveInternetCheck();
  }

  void _initLiveInternetCheck() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool isConnected = results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi) ||
          results.contains(ConnectivityResult.ethernet) ||
          results.contains(ConnectivityResult.vpn);

      if (!isConnected) {
        try {
          final result = await InternetAddress.lookup('google.com')
              .timeout(const Duration(seconds: 2));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            isConnected = true;
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _internetGranted = isConnected;
        });
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAllPermissions() async {
    final cameraStatus = await Permission.camera.status;

    bool biometricOk = false;
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('checkUsbDevices');
        if (result != null && result is Map) {
          final count = result['count'] ?? 0;
          if (count > 0) {
            biometricOk = true;
          }
        }
      } else {
        biometricOk = true;
      }
    } catch (_) {
      biometricOk = false;
    }

    bool internetOk = false;
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      if (connectivityResults.contains(ConnectivityResult.mobile) ||
          connectivityResults.contains(ConnectivityResult.wifi) ||
          connectivityResults.contains(ConnectivityResult.ethernet) ||
          connectivityResults.contains(ConnectivityResult.vpn)) {
        internetOk = true;
      }
    } catch (_) {}

    if (!internetOk) {
      try {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          internetOk = true;
        }
      } catch (_) {
        internetOk = false;
      }
    }

    if (mounted) {
      setState(() {
        _cameraGranted = cameraStatus.isGranted;
        _biometricGranted = biometricOk;
        _internetGranted = internetOk;
      });
    }
  }

  Future<void> _requestCamera() async {
    await Permission.camera.request();
    _checkAllPermissions();
  }

  Future<void> _requestBiometrics() async {
    await _checkAllPermissions();
    if (_biometricGranted) {
      Get.snackbar(
        "SecuGen USB Connected",
        "SecuGen fingerprint scanner detected via USB.",
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "USB Scanner Required",
        "Please connect SecuGen HU20 biometric device via USB OTG cable.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _handleLogin() {
    final userId = _userIdController.text.trim();
    final password = _passwordController.text.trim();
    if (userId.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter Operator ID",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (password.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please enter password",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!_cameraGranted || !_internetGranted) {
      Get.snackbar(
        "Security Check Required",
        "Camera and Internet connections are required to login.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    _loginController.login(operatorId: userId, password: password);
  }

  Widget _buildMiniCheck(String label, bool status, VoidCallback onTap) {
    const Color neonGreen = Color(0xFF10B981);
    const Color errorRed = Color(0xFFEF5350);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status ? Icons.check_circle : Icons.cancel,
                color: status ? neonGreen : errorRed,
                size: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: status
                        ? neonGreen
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Container(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                            color: Theme.of(context).primaryColor,
                          ),
                          onPressed: () {
                            Get.changeTheme(
                              Get.isDarkMode
                                  ? AppTheme.lightTheme
                                  : AppTheme.darkTheme,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 1,
                          ),
                        ],
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Theme.of(context).primaryColor.withOpacity(0.3),
                            Theme.of(context).primaryColor.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.face_retouching_natural,
                          color: Theme.of(context).primaryColor,
                          size: 32,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Secure Exam',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.titleLarge?.color,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Operator Attendance Console',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Container(
                        margin: const EdgeInsets.all(2.0),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                Theme.of(context).dividerColor.withOpacity(0.1),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 20.0,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .primaryColor
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.5),
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 14,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    CustomText.mono(
                                      'OPERATOR MODE',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                      letterSpacing: 1.1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: CustomText.regular(
                                'USER ID',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _userIdController,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: Theme.of(context).primaryColor,
                              decoration: InputDecoration(
                                hintText: 'Enter operator ID',
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                fillColor: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                suffixIcon: Icon(
                                  Icons.assignment_ind_outlined,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                  size: 18,
                                ),
                                border: Theme.of(context)
                                    .inputDecorationTheme
                                    .border,
                                enabledBorder: Theme.of(context)
                                    .inputDecorationTheme
                                    .enabledBorder,
                                focusedBorder: Theme.of(context)
                                    .inputDecorationTheme
                                    .focusedBorder,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'PASSWORD',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: TextStyle(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.color,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color
                                      ?.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                                fillColor: Theme.of(context)
                                    .inputDecorationTheme
                                    .fillColor,
                                filled: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.color,
                                    size: 18,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: Theme.of(context)
                                    .inputDecorationTheme
                                    .border,
                                enabledBorder: Theme.of(context)
                                    .inputDecorationTheme
                                    .enabledBorder,
                                focusedBorder: Theme.of(context)
                                    .inputDecorationTheme
                                    .focusedBorder,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniCheck(
                                    'Camera', _cameraGranted, _requestCamera),
                                _buildMiniCheck('SecuGen USB (Opt)',
                                    _biometricGranted, _requestBiometrics),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildMiniCheck('Internet', _internetGranted,
                                    _checkAllPermissions),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _handleLogin,
                                style:
                                    Theme.of(context).elevatedButtonTheme.style,
                                child: Text(
                                  'AUTHORIZE ACCESS',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Get.isDarkMode
                                        ? Colors.black
                                        : Colors.white,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Get.snackbar(
                                    "Information",
                                    "Please contact administrator to retrieve account details.",
                                    backgroundColor:
                                        Theme.of(context).colorScheme.primary,
                                    colorText: Colors.white,
                                  );
                                },
                                child: Text(
                                  'Forgot identification details?',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Center(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Get.to(() => const FingerTestScreen());
                                },
                                icon: const Icon(Icons.fingerprint, size: 14),
                                label:
                                    const Text('FINGERPRINT SENSOR DIAGNOSTIC'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Theme.of(context).primaryColor,
                                  side: BorderSide(
                                      color: Theme.of(context).primaryColor,
                                      width: 1.2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'SYSTEM V2.4.0 — ENCRYPTED NODE',
                          style: GoogleFonts.outfit(
                            fontSize: 9.5,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SECURE AES-256 OPERATOR TERMINAL',
                      style: GoogleFonts.outfit(
                        fontSize: 8.5,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
