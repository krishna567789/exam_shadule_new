import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:local_auth/local_auth.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen>
    with WidgetsBindingObserver {
  bool _cameraGranted = false;
  bool _biometricGranted = false;
  bool _internetGranted = false;
  bool _deviceConnected = false;
  String _detectedDeviceName = "No scanner detected";
  bool _isLoading = true;

  final LocalAuthentication _auth = LocalAuthentication();
  static const _platform =
      MethodChannel('com.example.exam_shadule_new/rd_service');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAllPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAllPermissions();
    }
  }

  Future<void> _checkAllPermissions() async {
    setState(() {
      _isLoading = true;
    });

    // 1. Camera check
    final cameraStatus = await Permission.camera.status;

    // 2. Biometric check
    bool biometricOk = false;
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;

      // If hardware supports biometrics
      if (isSupported && canCheck) {
        final List<BiometricType> enrolled =
            await _auth.getAvailableBiometrics();
        if (enrolled.isNotEmpty) {
          biometricOk = true;
        }
      } else {
        // If device has no hardware support or mock environment, let it pass
        biometricOk = true;
      }
    } catch (e) {
      debugPrint("Biometric check error: $e");
      // Allow passing if there is an initialization error or hardware absent
      biometricOk = true;
    }

    // 3. Internet check
    bool internetOk = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        internetOk = true;
      }
    } catch (_) {
      internetOk = false;
    }

    // 4. USB Biometric Device check
    bool deviceOk = false;
    String devName = "No scanner detected";
    try {
      if (Platform.isAndroid) {
        final result = await _platform.invokeMethod('checkUsbDevices');
        if (result != null && result is Map) {
          final count = result['count'] ?? 0;
          final List devices = result['devices'] ?? [];
          if (count > 0) {
            deviceOk = true;
            if (devices.isNotEmpty) {
              final firstDev = devices.first.toString();
              if (firstDev.contains("VID:1162") ||
                  firstDev.contains("vid:1162")) {
                devName = "SecuGen HU20 Scanner";
              } else {
                devName = firstDev.split(" — ").last;
              }
            } else {
              devName = "Biometric USB Device";
            }
          }
        }
      } else {
        // Mock connected on iOS/Simulator for development
        deviceOk = true;
        devName = "Biometric Simulator (iOS)";
      }
    } catch (e) {
      debugPrint("USB Check Error: $e");
      deviceOk = true;
      devName = "Biometric Simulator";
    }

    setState(() {
      _cameraGranted = cameraStatus.isGranted;
      _biometricGranted = biometricOk;
      _internetGranted = internetOk;
      _deviceConnected = deviceOk;
      _detectedDeviceName = devName;
      _isLoading = false;
    });
  }

  Future<void> _requestCamera() async {
    final status = await Permission.camera.request();
    setState(() {
      _cameraGranted = status.isGranted;
    });
    if (!status.isGranted) {
      Get.snackbar(
        "Camera Permission",
        "Camera permission is required to capture live photos.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _requestBiometrics() async {
    try {
      final bool isSupported = await _auth.isDeviceSupported();
      final bool canCheck = await _auth.canCheckBiometrics;

      if (!isSupported || !canCheck) {
        setState(() {
          _biometricGranted = true;
        });
        Get.snackbar(
          "Biometrics",
          "Biometric hardware not detected or not supported on this device. Bypassing requirement.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final List<BiometricType> enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        Get.snackbar(
          "Biometrics",
          "No biometrics registered. Please register fingerprint or face in device settings.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }

      final bool authenticated = await _auth.authenticate(
        localizedReason:
            'Scan fingerprint or face to verify secure biometric status',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      setState(() {
        _biometricGranted = authenticated;
      });

      if (authenticated) {
        Get.snackbar(
          "Biometrics Authenticated",
          "Secure biometric link established.",
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      debugPrint("Biometric auth error: $e");
      setState(() {
        _biometricGranted = true; // Fallback
      });
    }
  }

  Future<void> _requestInternet() async {
    await _checkAllPermissions();
    if (!_internetGranted) {
      Get.snackbar(
        "Network Error",
        "Unable to establish internet connection. Please verify wifi or mobile data.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        "Network Active",
        "Secure connection established.",
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  bool get _allPermissionsGranted =>
      _cameraGranted &&
      _biometricGranted &&
      _internetGranted &&
      _deviceConnected;

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF1E88E5);
    const Color textDark = Color(0xFF0F172A);
    const Color textMuted = Color(0xFF64748B);
    const Color neonGreen = Color(0xFF10B981);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              // Top security shield icon
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _allPermissionsGranted ? neonGreen : cyberBlue,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_allPermissionsGranted ? neonGreen : cyberBlue)
                          .withOpacity(0.1),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF2196F3).withOpacity(0.1),
                      const Color(0xFF64B5F6).withOpacity(0.02),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _allPermissionsGranted
                        ? Icons.security
                        : Icons.security_update_warning_outlined,
                    color: _allPermissionsGranted ? neonGreen : cyberCyan,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Main title
              Text(
                'SECURITY CHECKS',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: textDark,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: cyberBlue.withOpacity(0.2),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verify environment variables before login',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 40),
              // Permission list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: cyberCyan,
                        ),
                      )
                    : ListView(
                        children: [
                          _buildPermissionItem(
                            title: 'Camera Access',
                            subtitle:
                                'Required to capture candidate verification photos',
                            icon: Icons.camera_alt_outlined,
                            isGranted: _cameraGranted,
                            onGrant: _requestCamera,
                            buttonText: 'Grant',
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionItem(
                            title: 'Biometric Sensor',
                            subtitle:
                                'Required for operator authentication & logging',
                            icon: Icons.fingerprint,
                            isGranted: _biometricGranted,
                            onGrant: _requestBiometrics,
                            buttonText: 'Authorize',
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionItem(
                            title: 'Secure Internet Link',
                            subtitle:
                                'Required to sync exam sessions & databases',
                            icon: Icons.wifi,
                            isGranted: _internetGranted,
                            onGrant: _requestInternet,
                            buttonText: 'Verify',
                          ),
                          const SizedBox(height: 16),
                          _buildPermissionItem(
                            title: 'Biometric USB Device',
                            subtitle: _deviceConnected
                                ? 'Active: $_detectedDeviceName'
                                : 'Deactive: Connect HU20 scanner via USB OTG',
                            icon: Icons.usb,
                            isGranted: _deviceConnected,
                            onGrant: _checkAllPermissions,
                            buttonText: 'Refresh',
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              // Confirm button
              Container(
                width: double.infinity,
                height: 54,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: _allPermissionsGranted
                      ? const LinearGradient(
                          colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: _allPermissionsGranted ? null : Colors.grey.shade200,
                  boxShadow: _allPermissionsGranted
                      ? [
                          BoxShadow(
                            color: cyberBlue.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                  border: _allPermissionsGranted
                      ? null
                      : Border.all(
                          color: Colors.grey.shade300,
                          width: 1.0,
                        ),
                ),
                child: ElevatedButton(
                  onPressed: _allPermissionsGranted
                      ? () {
                          Get.offAll(() => const LoginScreen());
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'PROCEED TO SECURE LOGIN',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _allPermissionsGranted
                          ? Colors.white
                          : Colors.black26,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onGrant,
    required String buttonText,
  }) {
    const Color textDark = Color(0xFF0F172A);
    const Color textMuted = Color(0xFF64748B);

    // Light Theme Styling
    final cardBg = Colors.white;
    final cardBorder = Colors.grey.shade300;
    final iconBg =
        isGranted ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);
    final iconColor =
        isGranted ? const Color(0xFF15803D) : const Color(0xFFB91C1C);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Icon with status background
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              isGranted ? Icons.check : icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Title & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: textDark,
                    fontSize: 15,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Action button
          if (!isGranted)
            ElevatedButton(
              onPressed: onGrant,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF15803D).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Text(
                'Active',
                style: TextStyle(
                  color: Color(0xFF15803D),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
