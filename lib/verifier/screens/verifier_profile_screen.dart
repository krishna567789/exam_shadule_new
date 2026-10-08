import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controller/profile_controller.dart';
import '../../utils/app_theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text.dart';

class VerifierProfileScreen extends StatefulWidget {
  const VerifierProfileScreen({super.key});

  @override
  State<VerifierProfileScreen> createState() => _VerifierProfileScreenState();
}

class _VerifierProfileScreenState extends State<VerifierProfileScreen> {
  late final VerifierProfileController _c;

  @override
  void initState() {
    super.initState();
    _c = Get.put(VerifierProfileController());
    _c.prefillFromStorage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: CustomText.heading('VERIFIER PROFILE',
            fontSize: 16, letterSpacing: 1.5, color: AppTheme.textLight),
        backgroundColor: AppTheme.backgroundDark,
        foregroundColor: AppTheme.textLight,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText.regular(
              'Complete your profile to continue. Photo and Aadhaar are required.',
              fontSize: 13,
              color: AppTheme.textMuted,
            ),
            const SizedBox(height: 20),
            _labeledField('FULL NAME', _c.nameCtl),
            _labeledField('FATHER NAME', _c.fatherNameCtl),
            _labeledField('MOBILE NUMBER', _c.mobileCtl,
                keyboard: TextInputType.phone, maxLength: 15),
            _labeledField('EMAIL', _c.emailCtl, keyboard: TextInputType.emailAddress),
            _labeledField('ADDRESS', _c.addressCtl),
            Row(
              children: [
                Expanded(child: _labeledField('CITY', _c.cityCtl)),
                const SizedBox(width: 12),
                Expanded(child: _labeledField('STATE', _c.stateCtl)),
              ],
            ),
            const SizedBox(height: 20),
            CustomText.heading('DOCUMENTS',
                fontSize: 14, color: AppTheme.primaryNeon, letterSpacing: 1.5),
            const SizedBox(height: 12),
            Obx(() => Row(
                  children: [
                    Expanded(
                        child: _imagePicker('PHOTO', Icons.person,
                            _c.photoPath.value, () => _c.pickImage(field: 'photo'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _imagePicker('AADHAR FRONT', Icons.credit_card,
                            _c.aadharFrontPath.value,
                            () => _c.pickImage(field: 'aadharFront'))),
                    const SizedBox(width: 10),
                    Expanded(
                        child: _imagePicker('AADHAR BACK', Icons.credit_card,
                            _c.aadharBackPath.value,
                            () => _c.pickImage(field: 'aadharBack'))),
                  ],
                )),
            const SizedBox(height: 32),
            Obx(
              () => CustomButton(
                text: 'SUBMIT PROFILE',
                isLoading: _c.isLoading,
                backgroundColor: AppTheme.primaryNeon,
                textColor: AppTheme.backgroundDark,
                onPressed: _c.submitProfile,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController ctl,
      {TextInputType? keyboard, int? maxLength}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText.regular(label,
              fontSize: 12,
              color: AppTheme.primaryNeon,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600),
          const SizedBox(height: 6),
          TextField(
            controller: ctl,
            keyboardType: keyboard,
            maxLength: maxLength,
            style: const TextStyle(color: AppTheme.textLight),
            decoration: InputDecoration(
              counterText: "",
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
      ),
    );
  }

  Widget _imagePicker(String label, IconData icon, String? path, VoidCallback onTap) {
    final has = path != null && path.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: has ? AppTheme.successGreen : Colors.white.withOpacity(0.15)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            has
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.file(File(path), height: 56, width: 56, fit: BoxFit.cover),
                  )
                : Icon(icon, size: 32, color: AppTheme.textMuted),
            const SizedBox(height: 6),
            CustomText.regular(
              has ? 'RETAKE' : label,
              fontSize: 9,
              color: has ? AppTheme.successGreen : AppTheme.textMuted,
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
