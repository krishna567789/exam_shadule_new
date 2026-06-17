import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';
import '../controller/user_profile_controller.dart';
import 'login_screen.dart';

class OperatorProfileScreen extends StatefulWidget {
  const OperatorProfileScreen({super.key});

  @override
  State<OperatorProfileScreen> createState() => _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends State<OperatorProfileScreen> {
  final UserProfileController _profileController = Get.put(UserProfileController());

  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  bool _isLoading = true;
  String _operatorId = "OP-2024-99";

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _cityController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _profileController.nameController.text = prefs.getString('operator_name') ?? prefs.getString('name') ?? "Rahul Sharma";
        _profileController.centerNameController.text = prefs.getString('center_name') ?? "Delhi Examination Center";
        _profileController.centerCodeController.text = prefs.getString('center_code') ?? "DEX1234";

        String cityState = prefs.getString('operator_city_state') ?? "New Delhi, Delhi";
        List<String> parts = cityState.split(',');
        if (parts.length >= 2) {
          _cityController.text = parts[0].trim();
          _stateController.text = parts.sublist(1).join(',').trim();
        } else {
          _cityController.text = cityState;
          _stateController.text = "Delhi";
        }

        _profileController.mobileController.text = prefs.getString('operator_phone') ?? "+91 9876543210";
        _profileController.emailController.text = prefs.getString('operator_email') ?? "rahul.sharma@example.com";
        _profileController.fatherController.text = prefs.getString('father_name') ?? "N/A";
        
        _operatorId = prefs.getString('operator_id') ?? "OP-2024-99";

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('operator_name');
    await prefs.remove('operator_email');
    await prefs.remove('operator_phone');
    await prefs.remove('operator_city_state');
    await prefs.remove('center_name');
    await prefs.remove('center_code');

    // Clear controller files
    _profileController.profileImage.value = null;
    _profileController.frontImage.value = null;
    _profileController.backImage.value = null;

    Get.offAll(() => const LoginScreen());
  }

  void _handleSubmit() async {
    final name = _profileController.nameController.text.trim();
    final centerName = _profileController.centerNameController.text.trim();
    final centerCode = _profileController.centerCodeController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final phone = _profileController.mobileController.text.trim();
    final email = _profileController.emailController.text.trim();

    if (name.isEmpty ||
        centerName.isEmpty ||
        centerCode.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        phone.isEmpty ||
        email.isEmpty) {
      Get.snackbar(
        "Validation Error",
        "Please fill in all operator details to proceed.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_profileController.profileImage.value == null) {
      Get.snackbar(
        "Validation Error",
        "Please tap on the profile circle at the top to capture your photo.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_profileController.frontImage.value == null || _profileController.backImage.value == null) {
      Get.snackbar(
        "Validation Error",
        "Please capture both Aadhaar Front and Back photos to proceed.",
        backgroundColor: AppTheme.errorRed,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    _profileController.addressController.text = "$city, $state";
    await _profileController.submitForm();
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);
    const Color textMuted = Color(0xFF90A4AE);

    return Scaffold(
      backgroundColor: const Color(0xFF03081A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: cyberCyan),
          onPressed: _handleLogout,
        ),
        title: Text(
          "Operator Profile",
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            shadows: [
              Shadow(
                color: cyberBlue.withOpacity(0.5),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cyberBlue))
          : SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          child: Column(
                            children: [
                              // First Card: Profile & Name & Status/ID (Top-Left and Top-Right Brackets only)
                              _buildHudCard(
                                showTopLeft: true,
                                showTopRight: true,
                                showBottomLeft: false,
                                showBottomRight: false,
                                child: Column(
                                  children: [
                                    // Avatar Picker
                                    Obx(() {
                                      final imageFile = _profileController.profileImage.value;
                                      return GestureDetector(
                                        onTap: () => _profileController.pickImage(true),
                                        child: Stack(
                                          children: [
                                            Container(
                                              width: 100,
                                              height: 100,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: cyberBlue,
                                                  width: 2.0,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: cyberBlue.withOpacity(0.3),
                                                    blurRadius: 15,
                                                    spreadRadius: 1,
                                                  ),
                                                ],
                                              ),
                                              child: ClipOval(
                                                child: imageFile != null
                                                    ? Image.file(
                                                        imageFile,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Container(
                                                        color: const Color(0xFF0D254F).withOpacity(0.5),
                                                        child: const Icon(
                                                          Icons.face_retouching_natural,
                                                          size: 48,
                                                          color: cyberCyan,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                            Positioned(
                                              bottom: 0,
                                              right: 0,
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF2196F3),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: const Color(0xFF03081A),
                                                    width: 1.5,
                                                  ),
                                                ),
                                                child: const Icon(
                                                  Icons.camera_alt,
                                                  size: 14,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                    const SizedBox(height: 20),

                                    // Operator Name Field
                                    _buildNameField(cyberBlue),
                                    const SizedBox(height: 20),

                                    // Verified Status and ID Number badges
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D254F).withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF154385).withOpacity(0.6),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "VERIFIED STATUS",
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    color: textMuted,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle_outline,
                                                      color: cyberCyan,
                                                      size: 14,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Active",
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                        color: cyberCyan,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF0D254F).withOpacity(0.3),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF154385).withOpacity(0.6),
                                              ),
                                            ),
                                            child: Column(
                                              children: [
                                                Text(
                                                  "ID NUMBER",
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 10,
                                                    color: textMuted,
                                                    letterSpacing: 1.0,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  _operatorId,
                                                  style: GoogleFonts.outfit(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Second Card: Center Information (Top-Left and Bottom-Right Brackets only)
                              _buildHudCard(
                                showTopLeft: true,
                                showTopRight: false,
                                showBottomLeft: false,
                                showBottomRight: true,
                                child: Column(
                                  children: [
                                    _buildSectionHeader("Center Information", Icons.apartment, cyberBlue),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      icon: Icons.apartment,
                                      label: "Center Name",
                                      controller: _profileController.centerNameController,
                                      iconColor: cyberCyan,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      icon: Icons.qr_code,
                                      label: "Center Code",
                                      controller: _profileController.centerCodeController,
                                      iconColor: cyberCyan,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _buildInputField(
                                            icon: Icons.location_city,
                                            label: "City",
                                            controller: _cityController,
                                            iconColor: cyberCyan,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: _buildInputField(
                                            icon: Icons.map_outlined,
                                            label: "State",
                                            controller: _stateController,
                                            iconColor: cyberCyan,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Third Card: Contact Details
                              _buildHudCard(
                                showTopLeft: true,
                                showTopRight: false,
                                showBottomLeft: false,
                                showBottomRight: true,
                                child: Column(
                                  children: [
                                    _buildSectionHeader("Contact Details", Icons.contact_mail, cyberBlue),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      icon: Icons.phone,
                                      label: "Phone Number",
                                      controller: _profileController.mobileController,
                                      iconColor: cyberCyan,
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 16),
                                    _buildInputField(
                                      icon: Icons.mail_outline,
                                      label: "Email",
                                      controller: _profileController.emailController,
                                      iconColor: cyberCyan,
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Fourth Card: Aadhaar Documents
                              _buildHudCard(
                                showTopLeft: true,
                                showTopRight: false,
                                showBottomLeft: false,
                                showBottomRight: true,
                                child: Column(
                                  children: [
                                    _buildSectionHeader("Aadhaar Documents", Icons.badge, cyberBlue),
                                    const SizedBox(height: 16),
                                    Obx(() => Row(
                                          children: [
                                            _buildAadhaarUploadCard(
                                              label: "Aadhaar Front",
                                              imageFile: _profileController.frontImage.value,
                                              onTap: () => _profileController.pickImage(false, isFront: true),
                                              steelBlueColor: cyberCyan,
                                            ),
                                            const SizedBox(width: 12),
                                            _buildAadhaarUploadCard(
                                              label: "Aadhaar Back",
                                              imageFile: _profileController.backImage.value,
                                              onTap: () => _profileController.pickImage(false, isFront: false),
                                              steelBlueColor: cyberCyan,
                                            ),
                                          ],
                                        )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Info warning alert console box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0D254F).withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF154385).withOpacity(0.6),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: cyberCyan,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        "Please ensure all details match your current assignment before proceeding to the examination module.",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12,
                                          color: textMuted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Custom Proceed button at bottom
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Container(
                          width: double.infinity,
                          height: 54,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1976D2), Color(0xFF2196F3)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                  color: cyberBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4)),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              "CONFIRM & PROCEED",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                 ),
    );
  }

  Widget _buildHudCard({
    required Widget child,
    bool showTopLeft = true,
    bool showTopRight = true,
    bool showBottomLeft = true,
    bool showBottomRight = true,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(2.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF1A3D75).withOpacity(0.4),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: child,
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 1,
          width: double.infinity,
          color: const Color(0xFF154385).withOpacity(0.5),
        ),
      ],
    );
  }

  Widget _buildNameField(Color iconColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "OPERATOR NAME",
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF90A4AE),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _profileController.nameController,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1C2D42),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF154385).withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color iconColor,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: const Color(0xFF90A4AE),
            fontWeight: FontWeight.w500,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: const Color(0xFF154385).withOpacity(0.4),
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1976D2),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1C2D42),
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAadhaarUploadCard({
    required String label,
    required File? imageFile,
    required VoidCallback onTap,
    required Color steelBlueColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF0D254F).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF154385).withOpacity(0.6)),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: steelBlueColor, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      label.toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF90A4AE),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

