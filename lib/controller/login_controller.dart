import 'package:exam_shadule_new/screens/operator_profile_screen.dart';
import 'package:exam_shadule_new/screens/session_setup_screen.dart';
import 'package:exam_shadule_new/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class LoginController extends GetxController {
  login({required String email, required String password}) async {
    // Check network connectivity before attempting login
    try {
      var connectivityResults = await Connectivity().checkConnectivity();
      bool hasNet = connectivityResults.contains(ConnectivityResult.mobile) ||
          connectivityResults.contains(ConnectivityResult.wifi) ||
          connectivityResults.contains(ConnectivityResult.ethernet) ||
          connectivityResults.contains(ConnectivityResult.vpn);
      if (!hasNet) {
        Get.back(); // close any open dialog
        Get.snackbar('No Internet',
            'Please check your connection (Wi-Fi or Mobile Data) and try again.',
            backgroundColor: Colors.redAccent);
        return;
      }
    } catch (e) {
      // In case connectivity check fails, proceed with login but warn user
      print('Connectivity check failed: $e');
    }
    try {
      Get.dialog(
        const Center(
            child: CircularProgressIndicator(color: Color(0xff6388bd))),
        barrierDismissible: false,
      );

      // 1. Login API
      String loginUrl = "https://bio.ubroapi.space/api/registrars/login";
      var loginHeaders = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjZhM2QxNmM5MGUyZjBiMzMwNjM2MDk2MCIsInJvbGUiOiJvcGVyYXRvciIsImF1dGhTb3VyY2UiOiJyZWdpc3RyYXJzIiwiaWF0IjoxNzgyNDQzOTA2LCJleHAiOjE3ODI1MzAzMDZ9.UtEuew3WcYlJiemTFEs1vNJRDUDHrlnP64DrR4VDcYY',
      };
      var loginBody = {
        "operatorId": email,
        "password": password,
      };

      print("--- LOGIN REQUEST ---");
      print("URL: $loginUrl");
      print("Headers: $loginHeaders");
      print("Body: ${json.encode(loginBody)}");

      final loginResponse = await http.post(
        Uri.parse(loginUrl),
        headers: loginHeaders,
        body: json.encode(loginBody),
      );
      print("--- LOGIN RESPONSE ---");
      print("Status Code: ${loginResponse.statusCode}");
      print("Response Body: ${loginResponse.body}");
      print("----------------------");

      if (Get.isDialogOpen ?? false) Get.back();

      var loginData = json.decode(loginResponse.body);

      if (loginResponse.statusCode == 200 && loginData['status'] == true) {
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Save Auth Token
        String token = loginData['token'] ?? "";
        await prefs.setString('token', token);
        await prefs.setString('operator_email', email);

        print("--- SAVED BEARER TOKEN ---");
        print("Token: $token");
        print("--------------------------");

        // Save session data from login response
        var data = loginData['data'];
        if (data != null) {
          await prefs.setString('center_name', data['center_name'] ?? "");
          await prefs.setString('center_code', data['center_code'] ?? "");
          await prefs.setString('exam_name', data['exam_name'] ?? "");
          await prefs.setString(
              'shift_start_time', data['shift_start_time'] ?? "");
          await prefs.setString('shift_end_time', data['shift_end_time'] ?? "");
          if (data['center'] != null && data['center']['capacity'] != null) {
            await prefs.setInt('center_capacity', data['center']['capacity']);
          }
        }

        // 2. Check Profile API
        await checkProfileStatus(email, token);
      } else {
        print("Login Failed Status: ${loginResponse.statusCode}");
        print("Login Failed Body: ${loginResponse.body}");
        Get.snackbar(
          "Login Failed",
          loginData['message'] ?? "Invalid credentials",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (error, stackTrace) {
      print("Login Exception: $error");
      print("Login StackTrace: $stackTrace");
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar("Error", "Server connection failed: $error",
          backgroundColor: Colors.redAccent);
    }
  }

  Future<void> checkProfileStatus(String email, String token) async {
    try {
      String checkUrl =
          "https://bio.ubroapi.space/api/operator-users/profile/check?email=$email";
      var checkHeaders = {
        'Authorization': 'Bearer $token',
      };
      print("--- PROFILE CHECK REQUEST ---");
      print("URL: $checkUrl");
      print("Headers: $checkHeaders");
      final response = await http.get(
        Uri.parse(checkUrl),
        headers: checkHeaders,
      );

      print("--- PROFILE CHECK RESPONSE ---");
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("------------------------------");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var data = responseData['data'];
        bool profileCompleted = data['profileCompleted'] ?? false;

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_profile_completed', profileCompleted);

        if (profileCompleted) {
          var profile = data['profile'];
          if (profile != null) {
            await prefs.setString('operator_id_db', profile['id'] ?? "");
            await prefs.setString('operator_name', profile['name'] ?? "");
            await prefs.setString('father_name', profile['fatherName'] ?? "");
            await prefs.setString(
                'operator_phone', profile['mobileNumber'] ?? "");
            await prefs.setString('operator_city_state',
                "${profile['city']}, ${profile['state']}");
            await prefs.setString('center_name', profile['centerName'] ?? "");
            await prefs.setString('center_code', profile['centerCode'] ?? "");

            String shiftName = profile['shift'] ??
                data['shift'] ??
                profile['shiftName'] ??
                data['shiftName'] ??
                "";
            String examDate = profile['examDate'] ??
                data['examDate'] ??
                profile['exam_date'] ??
                data['exam_date'] ??
                "";
            String timing = profile['timing'] ??
                data['timing'] ??
                profile['shiftTiming'] ??
                data['shiftTiming'] ??
                "";

            String displayShift = shiftName;
            if (examDate.isNotEmpty) {
              displayShift = "$examDate - $shiftName";
            }
            if (timing.isNotEmpty) {
              displayShift += " ($timing)";
            }
            if (displayShift.isEmpty) displayShift = "N/A";

            await prefs.setString('shift', displayShift);
          }

          await prefs.setBool('is_logged_in', true);
          Get.snackbar("Welcome", "Login successful",
              backgroundColor: Colors.greenAccent);
          Get.offAll(() => const SessionSetupScreen());
        } else {
          // NEW USER: Go to Create Profile screen
          Get.snackbar(
              "Profile Required", "Please complete your profile details",
              backgroundColor: Colors.orangeAccent);
          Get.offAll(() => const OperatorProfileScreen());
        }
      } else {
        print("Profile Check Failed Status: ${response.statusCode}");
        print("Profile Check Failed Body: ${response.body}");
        // If profile check fails, default to profile screen for safety
        Get.offAll(() => const OperatorProfileScreen());
      }
    } catch (e, stackTrace) {
      print("Error checking profile: $e");
      print("StackTrace: $stackTrace");
      Get.offAll(() => const OperatorProfileScreen());
    }
  }

  Future<void> logout() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Also clear Hive data to ensure no sensitive info remains
      var box = Hive.box('candidates_box');
      await box.clear();

      Get.offAll(() => const LoginScreen());

      Get.snackbar(
        "Logged Out",
        "Session terminated successfully.",
        backgroundColor: Colors.blueAccent,
        colorText: Colors.white,
      );
    } catch (e) {
      print("Logout Error: $e");
    }
  }
}
