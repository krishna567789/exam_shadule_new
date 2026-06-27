import 'dart:convert';
import 'package:exam_shadule_new/controller/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString centerName = ''.obs;
  final RxString centerCode = ''.obs;
  final RxString examName = ''.obs;

  // New observables for v1/dashboard
  final RxInt totalCandidates = 0.obs;
  final RxInt presentCandidates = 0.obs;
  final RxInt absentCandidates = 0.obs;
  final RxInt syncedCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    getStoredData();
    fetchDashboardStats(); // Fetch from server
  }

  Future<void> fetchDashboardStats() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      
      print("--- FETCHING DASHBOARD STATS ---");
      final response = await http.get(
        Uri.parse('https://bio.ubroapi.space/api/v1/dashboard'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      print("Dashboard Stats Response: ${response.body}");

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data['status'] == true && data['data'] != null) {
          var stats = data['data'];
          totalCandidates.value = stats['totalStudents'] ?? 0;
          presentCandidates.value = stats['presentCount'] ?? 0;
          absentCandidates.value = stats['absentCount'] ?? 0;
          syncedCount.value = stats['syncedCount'] ?? 0;
        }
      }
    } catch (e) {
      print("Error fetching dashboard stats: $e");
    }
  }

  void getStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    centerCode.value = prefs.getString('center_code') ?? 'No Code Found';
    centerName.value = prefs.getString('center_name') ?? 'No Name Found';
    examName.value = prefs.getString('exam_name') ?? '';
  }

  String _formatBase64Size(String base64String) {
    if (base64String.isEmpty) return "0 KB";
    // Rough calculation: base64 is 4/3 the size of original data
    double sizeInBytes = base64String.length * (3 / 4);
    double sizeInKb = sizeInBytes / 1024;
    return "${sizeInKb.toStringAsFixed(2)} KB";
  }

  Future<void> syncAndUploadData() async {
    try {
      isLoading.value = true;
      var box = Hive.box('candidates_box');
      
      // Get candidates marked present but not synced
      final List allIndices = [];
      final List<Map<String, dynamic>> presentCandidates = [];
      
      for (int i = 0; i < box.length; i++) {
        var item = Map<String, dynamic>.from(box.getAt(i) as Map);
        if (item['attendanceStatus'] == true && item['syncStatus'] != true) {
          presentCandidates.add(item);
          allIndices.add(i);
        }
      }

      if (presentCandidates.isEmpty) {
        Get.snackbar("Info", "No new attendance records to sync.",
            backgroundColor: Colors.orangeAccent);
        isLoading.value = false;
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? operatorId = prefs.getString('operator_id_db');

      int successCount = 0;
      int failCount = 0;

      print("--- STARTING SEQUENTIAL SYNC ---");

      // Sync one-by-one to avoid "413 Request Entity Too Large"
      for (int i = 0; i < presentCandidates.length; i++) {
        var student = presentCandidates[i];
        int hiveIndex = allIndices[i];

        String livePhoto = student['livePhotoBase64'] ?? "";
        String rightThumb = student['rightThumbBase64'] ?? "";
        String leftThumb = student['leftThumbBase64'] ?? "";

        print("Syncing student: ${student['name']} (${i + 1}/${presentCandidates.length})");
        print("  - Live Photo Size: ${_formatBase64Size(livePhoto)}");
        print("  - Right Thumb Size: ${_formatBase64Size(rightThumb)}");
        print("  - Left Thumb Size: ${_formatBase64Size(leftThumb)}");

        Map<String, dynamic> payload = {
          "attendance_data": [
            {
              "studentId": student['id'] ?? student['_id'],
              "applicationId": student['applicationId'] ?? "",
              "rollno": student['rollNo'] ?? student['rollno'] ?? "",
              "name": student['name'] ?? "",
              "fatherName": student['fatherName'] ?? "",
              "motherName": student['motherName'] ?? "",
              "email": student['email'] ?? "",
              "mobile": student['mobile'] ?? "",
              "address": student['address'] ?? "",
              "examName": student['examName'] ?? student['exam_name'] ?? examName.value,
              "shiftName": student['shiftName'] ?? "",
              "shiftStart": student['shiftStart'] ?? "",
              "shiftEnd": student['shiftEnd'] ?? "",
              "centerName": student['centerName'] ?? centerName.value,
              "centerCode": student['centerCode'] ?? centerCode.value,
              "centerState": student['centerState'] ?? "",
              "centerDistrict": student['centerDistrict'] ?? "",
              "photo": student['livePhotoBase64'] ?? "",
              "rightThumbnail": student['rightThumbBase64'] ?? "",
              "leftThumbnail": student['leftThumbBase64'] ?? "",
              "biometricTemplate": "template_data",
              "attendanceTime": student['attendanceTime'] ?? DateTime.now().toIso8601String(),
              "biometricTime": student['biometricTime'] ?? DateTime.now().toIso8601String(),
              "operatorId": operatorId ?? ""
            }
          ]
        };

        print("Syncing student: ${student['name']} (${i + 1}/${presentCandidates.length})");

        try {
          final response = await http.post(
            Uri.parse('https://bio.ubroapi.space/api/attendance-reports/bulk'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(payload),
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            successCount++;
            // Update sync status in Hive immediately
            student['syncStatus'] = true;
            await box.putAt(hiveIndex, student);
          } else {
            failCount++;
            print("Failed for ${student['name']}: ${response.statusCode} - ${response.body}");
          }
        } catch (e) {
          failCount++;
          print("Error syncing ${student['name']}: $e");
        }
      }

      print("--- SYNC COMPLETED ---");
      print("Success: $successCount, Failed: $failCount");

      // Refresh dashboard stats from server
      fetchDashboardStats();

      if (successCount > 0) {
        Get.snackbar(
          "Sync Update", 
          "Successfully uploaded $successCount records.${failCount > 0 ? ' $failCount failed.' : ''}",
          backgroundColor: Colors.greenAccent,
          snackPosition: SnackPosition.BOTTOM,
        );
      } else if (failCount > 0) {
        Get.snackbar(
          "Sync Failed", 
          "Could not upload $failCount records. Check logs or internet connection.",
          backgroundColor: Colors.redAccent,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
        );
      }
      
    } catch (e, stackTrace) {
      print("--- SYNC EXCEPTION ---");
      print("Error: $e");
      print("StackTrace: $stackTrace");
      Get.snackbar("Error", "An error occurred: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
