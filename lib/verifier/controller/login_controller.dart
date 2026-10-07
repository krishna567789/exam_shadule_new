import 'dart:convert';
import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/verifier_models.dart';
import '../screens/dashboard_screen.dart';
import '../screens/login_screen.dart';
import '../screens/verifier_profile_screen.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../controller/base_controller.dart';
import 'session_controller.dart';

class VerifierLoginController extends BaseController {
  Future<bool> _checkConnectivity() async {
    try {
      final res = await Connectivity().checkConnectivity();
      final hasNet = res.contains(ConnectivityResult.mobile) ||
          res.contains(ConnectivityResult.wifi) ||
          res.contains(ConnectivityResult.ethernet) ||
          res.contains(ConnectivityResult.vpn);
      if (!hasNet) {
        showError('No internet. Please check Wi-Fi or Mobile Data and retry.');
        return false;
      }
      return true;
    } catch (e) {
      print('Connectivity check failed: $e');
      return true;
    }
  }

  Future<void> login({
    required String verifierId,
    required String password,
  }) async {
    if (verifierId.trim().isEmpty || password.trim().isEmpty) {
      showError('Enter Verifier ID and Password');
      return;
    }
    if (!await _checkConnectivity()) return;

    try {
      showLoading(withDialog: false);
      final body = {"verifierId": verifierId.trim(), "password": password};
      final res = await VerifierApiService.to.post(VerifierApiService.urlLogin, body);
      print("--- VERIFIER LOGIN ${res.statusCode} ---");
      print(res.body);
      hideLoading();

      final data = _tryDecode(res.body);
      if (res.statusCode == 200 && data != null && data['status'] == true) {
        final token = (data['token'] ?? '').toString();
        if (token.isEmpty) {
          showError('Login succeeded but no token returned');
          return;
        }
        await VerifierStorageService.to.saveToken(token);
        await VerifierStorageService.to.saveVerifierId(verifierId.trim());

        // Login response already carries profileCompleted + assignment data.
        VerifierSession? session;
        if (data['data'] is Map<String, dynamic>) {
          session = VerifierSession.fromJson(data['data'] as Map<String, dynamic>);
          // token-level profileCompleted flag is authoritative too
          if (data['profileCompleted'] == true) {
            session = _overrideProfileCompleted(session, true);
          }
        }
        if (session != null) VerifierSessionController.to.cacheFromSession(session);

        await VerifierStorageService.to.setLoggedIn(true);

        if (session != null && session.profileCompleted) {
          showSuccess("Welcome", "Login successful");
          Get.offAll(() => const VerifierDashboardScreen());
        } else {
          showSuccess("Profile Required", "Please complete your verifier profile");
          Get.offAll(() => const VerifierProfileScreen());
        }
      } else {
        final msg = data?['message'] ?? data?['msg'] ?? "Invalid credentials";
        showError(msg.toString());
      }
    } catch (e) {
      print("Login Exception: $e");
      hideLoading();
      showError("Server connection failed: $e");
    }
  }

  VerifierSession _overrideProfileCompleted(VerifierSession s, bool val) {
    return VerifierSession(
      id: s.id,
      verifierId: s.verifierId,
      examId: s.examId,
      examName: s.examName,
      examCode: s.examCode,
      centerId: s.centerId,
      centerCode: s.centerCode,
      centerName: s.centerName,
      centerDistrict: s.centerDistrict,
      centerState: s.centerState,
      centerFullAddress: s.centerFullAddress,
      profileCompleted: val,
      isActive: s.isActive,
      profileObj: s.profile,
    );
  }

  Map<String, dynamic>? _tryDecode(String body) {
    try {
      final d = jsonDecode(body);
      return d is Map<String, dynamic> ? d : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    try {
      await VerifierStorageService.to.clearAll();
      Get.offAll(() => const VerifierLoginScreen());
      Get.snackbar("Logged Out", "Session terminated.");
    } catch (e) {
      print("Logout error: $e");
    }
  }
}
