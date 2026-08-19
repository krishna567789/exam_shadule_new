import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/app_theme.dart';
import '../controller/user_profile_controller.dart';
import 'login_screen.dart';

class OperatorProfileScreen extends StatefulWidget {
  const OperatorProfileScreen({super.key});
  @override
  State<OperatorProfileScreen> createState() => _OperatorProfileScreenState();
}

class _OperatorProfileScreenState extends State<OperatorProfileScreen> {
  final UserProfileController _profileController =
      Get.put(UserProfileController());

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Attempt to fetch fresh details from server if ID exists
      if (prefs.getString('operator_id_db') != null) {
        await _profileController.fetchOperatorDetails();
      }

      setState(() {
        _profileController.operatorIdController.text = prefs.getString('operator_email') ?? "";
        _profileController.emailController.text =
            _profileController.emailController.text.isNotEmpty
                ? _profileController.emailController.text
                : (prefs.getString('operator_email') ?? "");
        _profileController.nameController.text =
            prefs.getString('operator_name') ?? "";
        _profileController.fatherController.text =
            prefs.getString('father_name') ?? "";
        _profileController.mobileController.text =
            prefs.getString('operator_phone') ?? "";

        String cityState = prefs.getString('operator_city_state') ?? "";
        if (cityState.contains(',')) {
          List<String> parts = cityState.split(',');
          _profileController.cityController.text = parts[0].trim();
          _profileController.stateController.text =
              parts.sublist(1).join(',').trim();
        } else {
          _profileController.cityController.text = cityState;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Get.offAll(() => const LoginScreen());
  }

  void _handleSubmit() async {
    if (_profileController.nameController.text.isEmpty ||
        _profileController.fatherController.text.isEmpty ||
        _profileController.mobileController.text.isEmpty ||
        _profileController.emailController.text.isEmpty ||
        _profileController.cityController.text.isEmpty ||
        _profileController.stateController.text.isEmpty ||
        _profileController.addressController.text.isEmpty) {
      Get.snackbar("Error", "All text fields are required",
          backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return;
    }

    if (_profileController.profileImage.value == null ||
        _profileController.frontImage.value == null ||
        _profileController.backImage.value == null) {
      Get.snackbar("Error", "Please capture all required photos",
          backgroundColor: AppTheme.errorRed, colorText: Colors.white);
      return;
    }

    await _profileController.submitForm();
  }

  void _showImageSourceDialog(bool isProfileImage, {bool isFront = false}) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Select Image Source",
                style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                    icon: Icons.camera_alt,
                    label: "Camera",
                    onTap: () {
                      Get.back();
                      _profileController.pickImage(
                          isProfileImage, ImageSource.camera,
                          isFront: isFront);
                    }),
                _buildSourceOption(
                    icon: Icons.photo_library,
                    label: "Gallery",
                    onTap: () {
                      Get.back();
                      _profileController.pickImage(
                          isProfileImage, ImageSource.gallery,
                          isFront: isFront);
                    }),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption(
      {required IconData icon,
      required String label,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 30),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).textTheme.bodyMedium?.color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cyberBlue = Color(0xFF2196F3);
    const Color cyberCyan = Color(0xFF64B5F6);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).primaryColor),
          onPressed: _handleLogout,
        ),
        title: Text(
          "Complete Profile",
          style: GoogleFonts.outfit(
            color: Theme.of(context).textTheme.titleLarge?.color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Get.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                color: Theme.of(context).primaryColor),
            onPressed: () => Get.changeTheme(
                Get.isDarkMode ? AppTheme.lightTheme : AppTheme.darkTheme),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: cyberBlue))
          : SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Photo Picker
                          Obx(() {
                            final imageFile =
                                _profileController.profileImage.value;
                            return GestureDetector(
                              onTap: () => _showImageSourceDialog(true),
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: cyberBlue, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                            color: cyberBlue.withOpacity(0.3),
                                            blurRadius: 10)
                                      ],
                                    ),
                                    child: ClipOval(
                                      child: imageFile != null
                                          ? Image.file(imageFile,
                                              fit: BoxFit.cover)
                                          : Container(
                                              color:
                                                  Colors.grey.withOpacity(0.1),
                                              child: const Icon(Icons.person,
                                                  size: 50, color: cyberBlue),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: CircleAvatar(
                                      backgroundColor: cyberBlue,
                                      radius: 15,
                                      child: const Icon(Icons.camera_alt,
                                          size: 15, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 24),

                          // Form Fields
                          _buildHudCard(
                            child: Column(
                              children: [
                                _buildInputField(
                                    icon: Icons.badge,
                                    label: "Operator ID",
                                    controller:
                                        _profileController.operatorIdController,
                                    isReadOnly: true),
                                const SizedBox(height: 16),
                                _buildInputField(
                                    icon: Icons.person,
                                    label: "Full Name",
                                    controller:
                                        _profileController.nameController),
                                const SizedBox(height: 16),
                                _buildInputField(
                                    icon: Icons.family_restroom,
                                    label: "Father's Name",
                                    controller:
                                        _profileController.fatherController),
                                const SizedBox(height: 16),
                                _buildInputField(
                                    icon: Icons.phone,
                                    label: "Mobile Number",
                                    maxLength: 10,
                                    controller:
                                        _profileController.mobileController,
                                    keyboardType: TextInputType.phone),
                                const SizedBox(height: 16),
                                _buildInputField(
                                    icon: Icons.email,
                                    label: "Email Address",
                                    controller:
                                        _profileController.emailController,
                                    keyboardType: TextInputType.emailAddress),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildHudCard(
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildInputField(
                                          icon: Icons.location_city,
                                          label: "City",
                                          controller: _profileController
                                              .cityController),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildInputField(
                                          icon: Icons.map,
                                          label: "State",
                                          controller: _profileController
                                              .stateController),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildInputField(
                                    icon: Icons.home,
                                    label: "Full Address",
                                    controller:
                                        _profileController.addressController),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Aadhaar Picker
                          _buildHudCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Aadhaar Documents",
                                    style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                Obx(() => Row(
                                      children: [
                                        _buildImagePickerBox(
                                          label: "Front Side",
                                          file: _profileController
                                              .frontImage.value,
                                          onTap: () => _showImageSourceDialog(
                                              false,
                                              isFront: true),
                                        ),
                                        const SizedBox(width: 12),
                                        _buildImagePickerBox(
                                          label: "Back Side",
                                          file: _profileController
                                              .backImage.value,
                                          onTap: () => _showImageSourceDialog(
                                              false,
                                              isFront: false),
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: const LinearGradient(colors: [
                                Color(0xFF1976D2),
                                Color(0xFF2196F3)
                              ]),
                            ),
                            child: ElevatedButton(
                              onPressed: _handleSubmit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text("CREATE PROFILE",
                                  style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHudCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: child,
    );
  }

  Widget _buildInputField(
      {required IconData icon,
      required String label,
      required TextEditingController controller,
      int? maxLength,
      bool isReadOnly = false,
      TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isReadOnly ? Colors.grey : null,
          ),
          maxLength: maxLength,
          readOnly: isReadOnly,
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, size: 20, color: Theme.of(context).primaryColor),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor:
                Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePickerBox(
      {required String label,
      required File? file,
      required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.2)),
          ),
          child: file != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(file, fit: BoxFit.cover))
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        color: Theme.of(context).primaryColor),
                    const SizedBox(height: 4),
                    Text(label,
                        style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: Theme.of(context).primaryColor)),
                  ],
                ),
        ),
      ),
    );
  }
}
