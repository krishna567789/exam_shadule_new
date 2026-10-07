import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../screens/dashboard_screen.dart';
import '../../controller/base_controller.dart';
import 'session_controller.dart';

/// Creates / completes the logged-in verifier's profile.
/// POST /api/verifiers/mobile/profile (multipart/form-data)
class VerifierProfileController extends BaseController {
  final nameCtl = TextEditingController();
  final fatherNameCtl = TextEditingController();
  final mobileCtl = TextEditingController();
  final emailCtl = TextEditingController();
  final addressCtl = TextEditingController();
  final stateCtl = TextEditingController();
  final cityCtl = TextEditingController();

  final photoPath = Rx<String?>(null);
  final aadharFrontPath = Rx<String?>(null);
  final aadharBackPath = Rx<String?>(null);

  final _picker = ImagePicker();

  void prefillFromStorage() {
    final st = VerifierStorageService.to;
    nameCtl.text = st.getString(VerifierStorageService.keyVerifierName) ?? '';
    fatherNameCtl.text = st.getString(VerifierStorageService.keyVerifierFatherName) ?? '';
    mobileCtl.text = st.getString(VerifierStorageService.keyVerifierPhone) ?? '';
    emailCtl.text = st.getString(VerifierStorageService.keyVerifierEmail) ?? '';
    addressCtl.text = st.getString(VerifierStorageService.keyVerifierAddress) ?? '';
    final cityState = st.getString(VerifierStorageService.keyVerifierCityState) ?? '';
    if (cityState.contains(',')) {
      final parts = cityState.split(',');
      cityCtl.text = parts[0].trim();
      stateCtl.text = parts.length > 1 ? parts[1].trim() : '';
    }
  }

  Future<void> pickImage({required String field}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked == null) return;
    switch (field) {
      case 'photo':
        photoPath.value = picked.path;
        break;
      case 'aadharFront':
        aadharFrontPath.value = picked.path;
        break;
      case 'aadharBack':
        aadharBackPath.value = picked.path;
        break;
    }
  }

  bool _validate() {
    if (nameCtl.text.trim().isEmpty) { showError('Name is required'); return false; }
    if (fatherNameCtl.text.trim().isEmpty) { showError('Father name is required'); return false; }
    final mobile = mobileCtl.text.trim();
    if (mobile.length < 10 || mobile.length > 15 || !RegExp(r'^\d+$').hasMatch(mobile)) {
      showError('Mobile number must be 10-15 digits');
      return false;
    }
    if (!GetUtils.isEmail(emailCtl.text.trim())) { showError('Valid email is required'); return false; }
    if (stateCtl.text.trim().isEmpty) { showError('State is required'); return false; }
    if (cityCtl.text.trim().isEmpty) { showError('City is required'); return false; }
    if (photoPath.value == null) { showError('Verifier photo is required'); return false; }
    if (aadharFrontPath.value == null) { showError('Aadhaar front is required'); return false; }
    if (aadharBackPath.value == null) { showError('Aadhaar back is required'); return false; }
    return true;
  }

  Future<void> submitProfile() async {
    if (!_validate()) return;
    try {
      showLoading(withDialog: false);
      final request = await VerifierApiService.to.multipartRequest(VerifierApiService.urlCreateProfile);
      request.fields.addAll({
        'name': nameCtl.text.trim(),
        'fatherName': fatherNameCtl.text.trim(),
        'mobileNumber': mobileCtl.text.trim(),
        'email': emailCtl.text.trim(),
        'address': addressCtl.text.trim(),
        'state': stateCtl.text.trim(),
        'city': cityCtl.text.trim(),
      });
      await _addFile(request, 'photo', photoPath.value!);
      await _addFile(request, 'aadharFront', aadharFrontPath.value!);
      await _addFile(request, 'aadharBack', aadharBackPath.value!);

      final streamed = await request.send();
      final res = await http.Response.fromStream(streamed);
      hideLoading();
      print("--- PROFILE SUBMIT ${res.statusCode} --- ${res.body}");

      Map<String, dynamic>? data;
      try { data = jsonDecode(res.body) as Map<String, dynamic>?; } catch (_) {}

      if (res.statusCode == 200 || res.statusCode == 201) {
        final ok = data == null || data['status'] == true;
        if (ok) {
          await VerifierSessionController.to.loadMe();
          await VerifierStorageService.to.setBool(VerifierStorageService.keyIsProfileCompleted, true);
          showSuccess("Profile Saved", "Verifier profile submitted");
          Get.offAll(() => const VerifierDashboardScreen());
        } else {
          showError((data['message'] ?? 'Profile submit failed').toString());
        }
      } else {
        final msg = (data != null && data['message'] != null)
            ? data['message'].toString()
            : 'Profile submit failed (${res.statusCode})';
        showError(msg);
      }
    } catch (e) {
      hideLoading();
      showError("Profile submit error: $e");
    }
  }

  Future<void> _addFile(http.MultipartRequest request, String field, String path) async {
    final name = path.split('/').last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : 'jpeg';
    request.files.add(
      await http.MultipartFile.fromPath(
        field,
        path,
        contentType: MediaType('image', ext == 'png' ? 'png' : 'jpeg'),
      ),
    );
  }

  @override
  void onClose() {
    nameCtl.dispose();
    fatherNameCtl.dispose();
    mobileCtl.dispose();
    emailCtl.dispose();
    addressCtl.dispose();
    stateCtl.dispose();
    cityCtl.dispose();
    super.onClose();
  }
}
