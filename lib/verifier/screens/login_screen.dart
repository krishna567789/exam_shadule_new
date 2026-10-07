import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/login_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text.dart';
import '../../screens/login_screen.dart';
import 'finger_test_screen.dart';

class VerifierLoginScreen extends StatefulWidget {
  const VerifierLoginScreen({super.key});

  @override
  State<VerifierLoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<VerifierLoginScreen> {
  final _verifierIdCtl = TextEditingController();
  final _passwordCtl = TextEditingController();
  bool _obscure = true;

  VerifierLoginController get _c => Get.find<VerifierLoginController>();

  @override
  void dispose() {
    _verifierIdCtl.dispose();
    _passwordCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primaryNeon.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryNeon.withOpacity(0.2),
                        blurRadius: 28,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset('assets/images/logo_mark.png',
                        width: 76, height: 76, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 24),
                CustomText.heading(
                  'SECURE EXAM',
                  fontSize: 26,
                  color: AppTheme.textLight,
                  letterSpacing: 2,
                ),
                CustomText.heading(
                  'VERIFIER CONSOLE',
                  fontSize: 15,
                  color: AppTheme.primaryNeon,
                  letterSpacing: 3,
                ),
                const SizedBox(height: 36),
                _field(
                  label: 'VERIFIER ID',
                  controller: _verifierIdCtl,
                  icon: Icons.badge,
                  upper: true,
                ),
                const SizedBox(height: 16),
                _field(
                  label: 'PASSWORD',
                  controller: _passwordCtl,
                  icon: Icons.lock,
                  obscure: _obscure,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: AppTheme.textMuted,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                const SizedBox(height: 30),
                Obx(
                  () => CustomButton(
                    text: 'LOGIN',
                    isLoading: _c.isLoading,
                    backgroundColor: AppTheme.primaryNeon,
                    textColor: AppTheme.backgroundDark,
                    onPressed: () => _c.login(
                      verifierId: _verifierIdCtl.text,
                      password: _passwordCtl.text,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () => Get.to(() => const VerifierFingerTestScreen()),
                  icon: const Icon(Icons.fingerprint, size: 16),
                  label: const Text('FINGERPRINT SENSOR DIAGNOSTIC'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryNeon,
                    side: BorderSide(
                        color: AppTheme.primaryNeon.withOpacity(0.6),
                        width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomText.regular(
                  'Authorized verification staff only',
                  fontSize: 12,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(height: 18),
                TextButton(
                  onPressed: () => Get.offAll(() => const LoginScreen()),
                  child: CustomText.regular(
                    'BACK TO OPERATOR CONSOLE LOGIN',
                    fontSize: 11,
                    color: AppTheme.primaryNeon,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool obscure = false,
    bool upper = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText.regular(
          label,
          fontSize: 12,
          color: AppTheme.primaryNeon,
          letterSpacing: 1.5,
          fontWeight: FontWeight.w600,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          textCapitalization:
              upper ? TextCapitalization.characters : TextCapitalization.none,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppTheme.textMuted),
            suffixIcon: suffix,
            filled: true,
            fillColor: AppTheme.surfaceDark,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryNeon, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
