import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_button.dart';
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
        "Required Fields",
        "Please fill in all operator details to proceed.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_profileController.profileImage.value == null) {
      Get.snackbar(
        "Upload Photo",
        "Please tap on the profile circle at the top to capture your photo.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (_profileController.frontImage.value == null || _profileController.backImage.value == null) {
      Get.snackbar(
        "Upload Aadhaar",
        "Please capture both Aadhaar Front and Back photos to proceed.",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.black,
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Set combined address field in controller
    _profileController.addressController.text = "$city, $state";

    // Call API submit
    await _profileController.submitForm();
  }

  @override
  Widget build(BuildContext context) {
    const Color steelBlueColor = Color(0xFF6388BD);
    const Color cardBgColor = Colors.white;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        backgroundColor: steelBlueColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _handleLogout,
        ),
        title: const Text(
          "Operator Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: steelBlueColor))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: cardBgColor,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24),
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
                                            color: const Color(0xFFD6E2F0),
                                            shape: BoxShape.circle,
                                            image: imageFile != null
                                                ? DecorationImage(
                                                    image: FileImage(imageFile),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: imageFile == null
                                              ? const Icon(
                                                  Icons.person,
                                                  size: 48,
                                                  color: Color(0xFF1E293B),
                                                )
                                              : null,
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: steelBlueColor,
                                              shape: BoxShape.circle,
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
                                const SizedBox(height: 16),
                                
                                // Operator Name Input Field
                                _buildNameField(steelBlueColor),
                                const SizedBox(height: 24),
                                const Divider(color: Color(0xFFE2E8F0), thickness: 1),
                                const SizedBox(height: 20),

                                // Center Information Section
                                _buildSectionHeader("Center Information", steelBlueColor),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  icon: Icons.apartment,
                                  label: "Center Name",
                                  controller: _profileController.centerNameController,
                                  iconColor: steelBlueColor,
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  icon: Icons.qr_code,
                                  label: "Center Code",
                                  controller: _profileController.centerCodeController,
                                  iconColor: steelBlueColor,
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                        icon: Icons.location_city,
                                        label: "City",
                                        controller: _cityController,
                                        iconColor: steelBlueColor,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildInputField(
                                        icon: Icons.map_outlined,
                                        label: "State",
                                        controller: _stateController,
                                        iconColor: steelBlueColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),

                                // Contact Details Section
                                _buildSectionHeader("Contact Details", steelBlueColor),
                                const SizedBox(height: 16),
                                _buildInputField(
                                  icon: Icons.phone,
                                  label: "Phone Number",
                                  controller: _profileController.mobileController,
                                  iconColor: steelBlueColor,
                                  keyboardType: TextInputType.phone,
                                ),
                                const SizedBox(height: 20),
                                _buildInputField(
                                  icon: Icons.mail_outline,
                                  label: "Email",
                                  controller: _profileController.emailController,
                                  iconColor: steelBlueColor,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 24),

                                // Aadhaar Upload Section
                                _buildSectionHeader("Aadhaar Documents", steelBlueColor),
                                const SizedBox(height: 16),
                                Obx(() => Row(
                                      children: [
                                        _buildAadhaarUploadCard(
                                          label: "Aadhaar Front",
                                          imageFile: _profileController.frontImage.value,
                                          onTap: () => _profileController.pickImage(false, isFront: true),
                                          steelBlueColor: steelBlueColor,
                                        ),
                                        const SizedBox(width: 16),
                                        _buildAadhaarUploadCard(
                                          label: "Aadhaar Back",
                                          imageFile: _profileController.backImage.value,
                                          onTap: () => _profileController.pickImage(false, isFront: false),
                                          steelBlueColor: steelBlueColor,
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Proceed Button at the bottom
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: CustomButton(
                      text: "Confirm & Proceed",
                      backgroundColor: steelBlueColor,
                      onPressed: _handleSubmit,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, Color textColor) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildNameField(Color iconColor) {
    return Column(
      children: [
        const Text(
          "Operator Name",
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _profileController.nameController,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
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
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: iconColor, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
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
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: imageFile != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    imageFile,
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_outlined, color: steelBlueColor, size: 28),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
