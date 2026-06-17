import 'package:exam_shadule_new/screens/operator_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginController extends GetxController {
  login({required String email, required String password}) async {
    try {
      // Show loading indicator
      Get.dialog(
        Center(child: CircularProgressIndicator(color: Color(0xff6388bd))),
        barrierDismissible: false, // Prevent closing dialog by tapping outside
      );

      var headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      print(email);
      print(password);
      final response = await http.post(
        Uri.parse("https://bio.ubrosoft.com/api/user/login"),
        headers: headers,
        body: {"email": email, "password": password},
      );
      print("API URL: ${response.request?.url} | Response: ${response.body}");

      // Close the loading dialog
      Get.back();

      // Check if the response status code is 200 (Success)
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();

        String? centerCode;
        String? centerName;

        if (responseData['center_code'] != null) {
          centerCode = responseData['center_code'].toString();
        } else if (responseData['user'] != null && responseData['user']['center_code'] != null) {
          centerCode = responseData['user']['center_code'].toString();
        }

        if (responseData['center_name'] != null) {
          centerName = responseData['center_name'].toString();
        } else if (responseData['user'] != null && responseData['user']['center_name'] != null) {
          centerName = responseData['user']['center_name'].toString();
        }

        if (centerCode != null) await prefs.setString('center_code', centerCode);
        if (centerName != null) await prefs.setString('center_name', centerName);

        if (responseData['user'] != null) {
          var userObj = responseData['user'];
          if (userObj['name'] != null) {
            await prefs.setString('operator_name', userObj['name'].toString());
          }
          if (userObj['email'] != null) {
            await prefs.setString('operator_email', userObj['email'].toString());
          }
          if (userObj['mobile_number'] != null) {
            await prefs.setString('operator_phone', userObj['mobile_number'].toString());
          } else if (userObj['phone'] != null) {
            await prefs.setString('operator_phone', userObj['phone'].toString());
          }

          String? city = userObj['city']?.toString();
          String? state = userObj['state']?.toString();
          if (city != null && state != null) {
            await prefs.setString('operator_city_state', "$city, $state");
          } else if (city != null) {
            await prefs.setString('operator_city_state', city);
          } else if (state != null) {
            await prefs.setString('operator_city_state', state);
          }
        }

        Get.snackbar(
          "Success",
          "Login Successful",
          backgroundColor: Colors.greenAccent,
        );
        Get.offAll(() => const OperatorProfileScreen());
        print("Login Successful");
      } else {
        // If the response status code is not 200, check the response body
        var responseData = json.decode(response.body);
        if (responseData['message'] != null) {
          // If a specific message is returned, display it
          Get.snackbar(
            "Failed",
            responseData['message'],
            backgroundColor: Colors.redAccent,
          );
        } else {
          // If no specific message, display a generic error
          Get.snackbar(
            "Failed",
            "An error occurred. Please try again.",
            backgroundColor: Colors.redAccent,
          );
        }
        print("Login Failed: ${responseData['message'] ?? 'Unknown error'}");
      }
    } catch (error) {
      // Close the loading dialog
      Get.back();

      Get.snackbar(
        "Failed",
        "Login Failed: $error",
        backgroundColor: Colors.redAccent,
      );
      print(error);
    }
  }
}
