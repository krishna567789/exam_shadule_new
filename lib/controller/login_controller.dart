import 'package:exam_shadule_new/screens/operator_profile_screen.dart';
import 'package:exam_shadule_new/screens/session_setup_screen.dart';
import 'package:exam_shadule_new/screens/login_screen.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/operator_profile_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'base_controller.dart';
import 'dashboard_controller.dart';
import 'download_controller.dart';

class LoginController extends BaseController {
  
  String? _extractValue(List<dynamic> targets, List<String> keys) {
    for (var target in targets) {
      if (target is Map) {
        for (var key in keys) {
          var val = target[key];
          if (val != null) {
            String str = val.toString().trim();
            if (str.isNotEmpty && str.toLowerCase() != "null") {
              return str;
            }
          }
        }
      }
    }
    return null;
  }

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

        // Save session data from login response flexibly (handling all potential backend formats)
        var data = loginData['data'];
        final targets = [
          data,
          loginData,
          data is Map ? data['center'] : null,
          loginData['center'],
          data is Map ? data['operator'] : null,
          loginData['operator'],
          data is Map ? data['user'] : null,
          loginData['user'],
          data is Map ? data['exam'] : null,
          loginData['exam'],
          data is Map ? data['shift'] : null,
          loginData['shift'],
        ];

        String? centerCode = _extractValue(targets, ['centerCode', 'center_code', 'center_id', 'centerId', 'code', 'centercode']);
        String? centerName = _extractValue(targets, ['centerName', 'center_name', 'name', 'centername', 'school_name', 'schoolName']);
        String? examName = _extractValue(targets, ['examName', 'exam_name', 'exam', 'exam_title', 'examTitle']);
        String? shiftName = _extractValue(targets, ['shift', 'shiftName', 'shift_name']);
        String? shiftStartTime = _extractValue(targets, ['shift_start_time', 'shiftStartTime', 'shiftStart', 'shift_start', 'startTime', 'start_time']);
        String? shiftEndTime = _extractValue(targets, ['shift_end_time', 'shiftEndTime', 'shiftEnd', 'shift_end', 'endTime', 'end_time']);
        String? capacityStr = _extractValue(targets, ['capacity', 'centerCapacity', 'center_capacity']);

        print("--- EXTRACTED LOGIN DATA ---");
        print("centerCode: $centerCode");
        print("centerName: $centerName");
        print("examName: $examName");
        print("shiftName: $shiftName");
        print("shiftStartTime: $shiftStartTime");
        print("shiftEndTime: $shiftEndTime");
        print("----------------------------");

        if (centerCode != null && centerCode.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyCenterCode, centerCode);
        }
        if (centerName != null && centerName.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyCenterName, centerName);
        }
        if (examName != null && examName.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyExamName, examName);
        }
        if (shiftStartTime != null && shiftStartTime.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyShiftStartTime, shiftStartTime);
        }
        if (shiftEndTime != null && shiftEndTime.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyShiftEndTime, shiftEndTime);
        }
        if (shiftName != null && shiftName.isNotEmpty) {
          await StorageService.to.setString(StorageService.keyShift, shiftName);
        }
        if (capacityStr != null) {
          int? cap = int.tryParse(capacityStr);
          if (cap != null) {
            await StorageService.to.setInt(StorageService.keyCenterCapacity, cap);
          }
        }

        // 2. Check Profile API
        await checkProfileStatus(operatorId, token);
      } else {
        showError(loginData['message'] ?? "Invalid credentials");
      }
    } catch (error) {
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
          try {
            final myProfileRes = await ApiService.to.getMyProfile();
            if (myProfileRes.statusCode == 200) {
              var pData = json.decode(myProfileRes.body);
              var resModel = OperatorProfileResponse.fromJson(pData);
              if (resModel.data?.profile != null) {
                await StorageService.to.saveOperatorProfile(resModel.data!.profile!);
              }
            }
          } catch (pe) {
            print("Error fetching full my-profile in login: $pe");
          }

          var profile = data['profile'];
          if (profile != null) {
            if (profile['id'] != null) {
              await StorageService.to.setString(StorageService.keyOperatorIdDb, profile['id'].toString());
            }
            if (profile['name'] != null && profile['name'].toString().isNotEmpty) {
              await StorageService.to.setString(StorageService.keyOperatorName, profile['name'].toString());
            }
            if (profile['fatherName'] != null && profile['fatherName'].toString().isNotEmpty) {
              await StorageService.to.setString(StorageService.keyFatherName, profile['fatherName'].toString());
            }
            if (profile['mobileNumber'] != null && profile['mobileNumber'].toString().isNotEmpty) {
              await StorageService.to.setString(StorageService.keyOperatorPhone, profile['mobileNumber'].toString());
            }
            if (profile['city'] != null || profile['state'] != null) {
              await StorageService.to.setString(StorageService.keyOperatorCityState, "${profile['city'] ?? ''}, ${profile['state'] ?? ''}");
            }

            // CRUCIAL: Only update Center details if profile explicitly provides a non-empty value!
            String? profileCenterName = _extractValue([profile, data], ['centerName', 'center_name', 'name']);
            if (profileCenterName != null && profileCenterName.isNotEmpty) {
              await StorageService.to.setString(StorageService.keyCenterName, profileCenterName);
            }

            String? profileCenterCode = _extractValue([profile, data], ['centerCode', 'center_code', 'code']);
            if (profileCenterCode != null && profileCenterCode.isNotEmpty) {
              await StorageService.to.setString(StorageService.keyCenterCode, profileCenterCode);
            }

            String? shiftName = _extractValue([profile, data], ['shift', 'shiftName', 'shift_name']);
            String? examDate = _extractValue([profile, data], ['examDate', 'exam_date', 'date']);
            String? timing = _extractValue([profile, data], ['timing', 'shiftTiming', 'shift_timing']);

            String displayShift = shiftName ?? "";
            if (examDate != null && examDate.isNotEmpty) displayShift = "$examDate - $displayShift";
            if (timing != null && timing.isNotEmpty) displayShift += " ($timing)";

            if (displayShift.trim().isNotEmpty && displayShift.trim() != "N/A") {
              await StorageService.to.setString(StorageService.keyShift, displayShift);
            }
          }

          // Sync data into controllers if already registered
          if (Get.isRegistered<DashboardController>()) {
            Get.find<DashboardController>().getStoredData();
          }
          if (Get.isRegistered<DownloadController>()) {
            Get.find<DownloadController>().getStoredSessionData();
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
