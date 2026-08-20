import 'package:exam_shadule_new/screens/operator_profile_screen.dart';
import 'package:exam_shadule_new/screens/session_setup_screen.dart';
import 'package:exam_shadule_new/screens/login_screen.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'base_controller.dart';

class LoginController extends BaseController {
  
  Future<bool> _checkConnectivity() async {
    try {
      var connectivityResults = await Connectivity().checkConnectivity();
      bool hasNet = connectivityResults.contains(ConnectivityResult.mobile) ||
          connectivityResults.contains(ConnectivityResult.wifi) ||
          connectivityResults.contains(ConnectivityResult.ethernet) ||
          connectivityResults.contains(ConnectivityResult.vpn);
      if (!hasNet) {
        showError('Please check your connection (Wi-Fi or Mobile Data) and try again.');
        return false;
      }
      return true;
    } catch (e) {
      print('Connectivity check failed: $e');
      return true; // Proceed if check fails
    }
  }

  login({required String operatorId, required String password}) async {
    if (!await _checkConnectivity()) return;

    try {
      showLoading();

      var loginBody = {
        "operatorId": operatorId,
        "password": password,
      };

      final loginResponse = await ApiService.to.post(ApiService.urlLogin, loginBody);
      
      print("--- LOGIN RESPONSE ---");
      print("Status Code: ${loginResponse.statusCode}");
      print("Response Body: ${loginResponse.body}");
      print("----------------------");

      hideLoading();

      var loginData = json.decode(loginResponse.body);

      if (loginResponse.statusCode == 200 && loginData['status'] == true) {
        // Save Auth Token
        String token = loginData['token'] ?? "";
        await StorageService.to.saveToken(token);
        await StorageService.to.saveOperatorEmail(operatorId);
        await StorageService.to.saveLoginOperatorId(operatorId);

        // Save session data from login response
        var data = loginData['data'];
        if (data != null) {
          await StorageService.to.setString(StorageService.keyCenterName, data['center_name'] ?? "");
          await StorageService.to.setString(StorageService.keyCenterCode, data['center_code'] ?? "");
          await StorageService.to.setString(StorageService.keyExamName, data['exam_name'] ?? "");
          await StorageService.to.setString(StorageService.keyShiftStartTime, data['shift_start_time'] ?? "");
          await StorageService.to.setString(StorageService.keyShiftEndTime, data['shift_end_time'] ?? "");
          if (data['center'] != null && data['center']['capacity'] != null) {
            await StorageService.to.setInt(StorageService.keyCenterCapacity, data['center']['capacity']);
          }
        }

        // 2. Check Profile API
        await checkProfileStatus(operatorId, token);
      } else {
        showError(loginData['message'] ?? "Invalid credentials");
      }
    } catch (error, stackTrace) {
      print("Login Exception: $error");
      hideLoading();
      showError("Server connection failed: $error");
    }
  }

  Future<void> checkProfileStatus(String operatorId, String token) async {
    try {
      final response = await ApiService.to.get(ApiService.urlCheckProfile, queryParams: {'operatorId': operatorId});

      print("--- PROFILE CHECK RESPONSE ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("------------------------------");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['data'];
        bool profileCompleted = data['profileCompleted'] ?? false;

        await StorageService.to.setBool(StorageService.keyIsProfileCompleted, profileCompleted);

        if (profileCompleted) {
          var profile = data['profile'];
          if (profile != null) {
            await StorageService.to.setString(StorageService.keyOperatorIdDb, profile['id'] ?? "");
            await StorageService.to.setString(StorageService.keyOperatorName, profile['name'] ?? "");
            await StorageService.to.setString(StorageService.keyFatherName, profile['fatherName'] ?? "");
            await StorageService.to.setString(StorageService.keyOperatorPhone, profile['mobileNumber'] ?? "");
            await StorageService.to.setString(StorageService.keyOperatorCityState, "${profile['city']}, ${profile['state']}");
            await StorageService.to.setString(StorageService.keyCenterName, profile['centerName'] ?? "");
            await StorageService.to.setString(StorageService.keyCenterCode, profile['centerCode'] ?? "");

            String shiftName = profile['shift'] ?? data['shift'] ?? profile['shiftName'] ?? data['shiftName'] ?? "";
            String examDate = profile['examDate'] ?? data['examDate'] ?? profile['exam_date'] ?? data['exam_date'] ?? "";
            String timing = profile['timing'] ?? data['timing'] ?? profile['shiftTiming'] ?? data['shiftTiming'] ?? "";

            String displayShift = shiftName;
            if (examDate.isNotEmpty) displayShift = "$examDate - $shiftName";
            if (timing.isNotEmpty) displayShift += " ($timing)";
            if (displayShift.isEmpty) displayShift = "N/A";

            await StorageService.to.setString(StorageService.keyShift, displayShift);
          }

          await StorageService.to.setLoggedIn(true);
          showSuccess("Welcome", "Login successful");
          Get.offAll(() => const SessionSetupScreen());
        } else {
          showSuccess("Profile Required", "Please complete your profile details");
          Get.offAll(() => const OperatorProfileScreen());
        }
      } else {
        Get.offAll(() => const OperatorProfileScreen());
      }
    } catch (e) {
      print("Error checking profile: $e");
      Get.offAll(() => const OperatorProfileScreen());
    }
  }

  Future<void> logout() async {
    try {
      await StorageService.to.clearAll();
      Get.offAll(() => const LoginScreen());
      Get.snackbar("Logged Out", "Session terminated successfully.");
    } catch (e) {
      print("Logout Error: $e");
    }
  }
}
