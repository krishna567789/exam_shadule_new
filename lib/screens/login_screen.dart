import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../controller/login_controller.dart';
import 'operator_profile_screen.dart';
import '../widgets/custom_text.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ignore: unused_field
  final LoginController _loginController = Get.put(LoginController());
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
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
    Get.offAll(() => const OperatorProfileScreen());
    // _loginController.login(
    //   email: userId,
    //   password: password,
    // );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
                  return SingleChildScrollView(
                    physics: isKeyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    child: Container(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Neon circular face logo
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E88E5),
                                width: 2.0,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1E88E5).withOpacity(0.4),
                                  blurRadius: 15,
                                  spreadRadius: 1,
                                ),
                              ],
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFF0D47A1).withOpacity(0.3),
                                  const Color(0xFF1976D2).withOpacity(0.1),
                                ],
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.face_retouching_natural,
                                color: Color(0xFF64B5F6),
                                size: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Header title "BioSecure"
                          Text(
                            'BioSecure',
                            style: GoogleFonts.outfit(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.5,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFF1E88E5).withOpacity(0.8),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle
                          Text(
                            'Operator Attendance Console',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF90A4AE),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Login HUD container Card
                          Container(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Container(
                              margin: const EdgeInsets.all(2.0),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0A1329).withOpacity(0.8),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF1A3D75).withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: 24.0,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                      // Operator Mode pill
                                      Center(
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0D254F),
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: const Color(0xFF154385),
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.person_outline,
                                                size: 16,
                                                color: Color(0xFF4A90E2),
                                              ),
                                              const SizedBox(width: 8),
                                               CustomText.mono(
                                                 'OPERATOR MODE',
                                                 fontSize: 12,
                                                 fontWeight: FontWeight.bold,
                                                 color: const Color(0xFF90CAF9),
                                                 letterSpacing: 1.1,
                                               ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // USER ID Field
                                      Align(
                                        alignment: Alignment.centerLeft,
                                         child: CustomText.regular(
                                           'USER ID',
                                           fontSize: 13,
                                           fontWeight: FontWeight.bold,
                                           color: const Color(0xFF90A4AE),
                                           letterSpacing: 1.2,
                                         ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _userIdController,
                                        style: const TextStyle(
                                          color: Color(0xFF1C2D42),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        cursorColor: const Color(0xFF1E88E5),
                                        decoration: InputDecoration(
                                          hintText: 'Enter operator ID',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF78909C),
                                            fontSize: 15,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          suffixIcon: const Icon(
                                            Icons.assignment_ind_outlined,
                                            color: Color(0xFF546E7A),
                                            size: 22,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF1E88E5),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // PASSWORD Field
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'PASSWORD',
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xFF90A4AE),
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: _passwordController,
                                        obscureText: true,
                                        style: const TextStyle(
                                          color: Color(0xFF1C2D42),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        cursorColor: const Color(0xFF1E88E5),
                                        decoration: InputDecoration(
                                          hintText: '••••••••',
                                          hintStyle: const TextStyle(
                                            color: Color(0xFF78909C),
                                            fontSize: 15,
                                          ),
                                          fillColor: Colors.white,
                                          filled: true,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 16,
                                          ),
                                          suffixIcon: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF546E7A),
                                            size: 22,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(8),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF1E88E5),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      // AUTHORIZE ACCESS Button
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color(0xFF1565C0).withOpacity(0.3),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: ElevatedButton(
                                          onPressed: _handleLogin,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF1E88E5),
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: Text(
                                            'AUTHORIZE ACCESS',
                                            style: GoogleFonts.outfit(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      // Forgot link
                                      Center(
                                        child: TextButton(
                                          onPressed: () {
                                            Get.snackbar(
                                              "Information",
                                              "Please contact administrator to retrieve account details.",
                                              backgroundColor: const Color(0xFF0D254F),
                                              colorText: Colors.white,
                                            );
                                          },
                                          child: Text(
                                            'Forgot identification details?',
                                            style: GoogleFonts.outfit(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF42A5F5),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          const SizedBox(height: 24),
                          // Footer with shield check icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.verified_user_outlined,
                                size: 14,
                                color: Color(0xFF455A64),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SYSTEM V2.4.0 — ENCRYPTED NODE',
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  color: const Color(0xFF455A64),
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Secure terminal text
                          Text(
                            'SECURE AES-256 OPERATOR TERMINAL',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: const Color(0xFF37474F),
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


