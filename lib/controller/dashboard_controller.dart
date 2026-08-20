import 'dart:convert';
import 'package:exam_shadule_new/controller/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/notification_service.dart';

class DashboardController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString centerName = ''.obs;
  final RxString centerCode = ''.obs;
  final RxString examName = ''.obs;
  final RxString operatorName = ''.obs;
  final RxString operatorPhone = ''.obs;
  final RxString operatorEmail = ''.obs;
  final RxString operatorCityState = ''.obs;
  final RxString fatherName = ''.obs;
  final RxString centerCapacity = ''.obs;

  // Global Stats
  final RxInt globalTotal = 0.obs;
  final RxInt globalPresent = 0.obs;
  final RxInt globalAbsent = 0.obs;

  // Local Device Stats
  final RxInt localTotal = 0.obs;
  final RxInt localPresent = 0.obs;
  final RxInt localAbsent = 0.obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isBackgroundSyncRunning = false;

  @override
  void onInit() {
    super.onInit();
    getStoredData();
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      if (results.contains(ConnectivityResult.mobile) ||
          results.contains(ConnectivityResult.wifi)) {
        if (!_isBackgroundSyncRunning) {
          print("Internet restored. Auto-syncing pending data...");
          backgroundSync();
        }
      }
    });
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  void getStoredData() async {
    centerCode.value = StorageService.to.getString(StorageService.keyCenterCode) ?? 'No Code Found';
    centerName.value = StorageService.to.getString(StorageService.keyCenterName) ?? 'No Name Found';
    examName.value = StorageService.to.getString(StorageService.keyCenterName) ?? ''; // Using center name as school name if exam name empty
    
    // Check if actual exam name exists
    String? storedExam = StorageService.to.getString(StorageService.keyExamName);
    if(storedExam != null && storedExam.isNotEmpty) examName.value = storedExam;

    operatorName.value = StorageService.to.getString(StorageService.keyOperatorName) ?? 'N/A';
    operatorPhone.value = StorageService.to.getString(StorageService.keyOperatorPhone) ?? 'N/A';
    operatorEmail.value = StorageService.to.getString(StorageService.keyOperatorEmail) ?? 'N/A';
    operatorCityState.value = StorageService.to.getString(StorageService.keyOperatorCityState) ?? 'N/A';
    fatherName.value = StorageService.to.getString(StorageService.keyFatherName) ?? 'N/A';
    
    int? capacity = StorageService.to.getInt(StorageService.keyCenterCapacity);
    centerCapacity.value = capacity != null ? capacity.toString() : 'N/A';

    // Global Stats from API response
    globalTotal.value = StorageService.to.getInt(StorageService.keyGlobalTotal) ?? 0;
    globalPresent.value = StorageService.to.getInt(StorageService.keyGlobalPresent) ?? 0;
    globalAbsent.value = StorageService.to.getInt(StorageService.keyGlobalAbsent) ?? 0;

    refreshLocalStats();
  }

  void refreshLocalStats() {
    var box = Hive.box('candidates_box');
    localTotal.value = box.length;
    localPresent.value = box.values.where((s) => (s as Map)['attendanceStatus'] == true).length;
    localAbsent.value = localTotal.value - localPresent.value;
  }

  String _formatBase64Size(String base64String) {
    if (base64String.isEmpty) return "0 KB";
    // Rough calculation: base64 is 4/3 the size of original data
    double sizeInBytes = base64String.length * (3 / 4);
    double sizeInKb = sizeInBytes / 1024;
    return "${sizeInKb.toStringAsFixed(2)} KB";
  }

  String _cleanBase64(dynamic raw) {
    if (raw == null) return "";
    String str = raw.toString().trim();
    if (str.isEmpty) return "";
    if (str.contains(',')) {
      return str.split(',').last.trim();
    }
    return str;
  }

  Map<String, dynamic> _buildBiometricDataMap(Map<String, dynamic> student) {
    String leftBase64 = _cleanBase64(student['leftThumbBase64']);
    String rightBase64 = _cleanBase64(student['rightThumbBase64']);
    String fallbackTemplate = _cleanBase64(student['biometricTemplate'] ?? "");

    if (student['biometricData'] != null && student['biometricData'] is Map) {
      Map<String, dynamic> existing =
          Map<String, dynamic>.from(student['biometricData'] as Map);

      String template =
          _cleanBase64(existing['TemplateBase64'] ?? fallbackTemplate);
      if (template.isEmpty) template = fallbackTemplate;

      String rightTemplate =
          _cleanBase64(existing['Right_TemplateBase64'] ?? template);
      if (rightTemplate.isEmpty) rightTemplate = template;

      String wsqImg = leftBase64.isNotEmpty
          ? leftBase64
          : _cleanBase64(existing['WSQImage'] ?? "");
      String bmpImg = leftBase64.isNotEmpty
          ? leftBase64
          : _cleanBase64(existing['BMPBase64'] ?? wsqImg);
      int wsqSize =
          wsqImg.isNotEmpty ? wsqImg.length : (existing['WSQImageSize'] ?? 0);

      String rWsqImg = rightBase64.isNotEmpty
          ? rightBase64
          : _cleanBase64(existing['Right_WSQImage'] ?? "");
      String rBmpImg = rightBase64.isNotEmpty
          ? rightBase64
          : _cleanBase64(existing['Right_BMPBase64'] ?? rWsqImg);
      int rWsqSize = rWsqImg.isNotEmpty
          ? rWsqImg.length
          : (existing['Right_WSQImageSize'] ?? 0);

      return {
        "SerialNumber": existing['SerialNumber'] ?? "H54170101182",
        "ImageHeight": existing['ImageHeight'] ?? 400,
        "ImageWidth": existing['ImageWidth'] ?? 300,
        "ImageDPI": existing['ImageDPI'] ?? 500,
        "Left_ImageQuality":
            existing['Left_ImageQuality'] ?? existing['ImageQuality'] ?? 80,
        "Left_NFIQ": existing['Left_NFIQ'] ?? existing['NFIQ'] ?? 2,
        "Left_TemplateBase64": template,
        "Left_WSQImageSize": wsqSize,
        "Left_WSQImage": wsqImg,
        "Left_BMPBase64": bmpImg,
        "Right_ImageQuality": existing['Right_ImageQuality'] ?? 80,
        "Right_NFIQ": existing['Right_NFIQ'] ?? 2,
        "Right_TemplateBase64": rightTemplate,
        "Right_WSQImageSize": rWsqSize,
        "Right_WSQImage": rWsqImg,
        "Right_BMPBase64": rBmpImg,
      };
    }

    return {
      "SerialNumber": "H54170101182",
      "ImageHeight": 400,
      "ImageWidth": 300,
      "ImageDPI": 500,
      "Left_ImageQuality": 80,
      "Left_NFIQ": 2,
      "Left_TemplateBase64": fallbackTemplate,
      "Left_WSQImageSize": leftBase64.length,
      "Left_WSQImage": leftBase64,
      "Left_BMPBase64": leftBase64,
      "Right_ImageQuality": 80,
      "Right_NFIQ": 2,
      "Right_TemplateBase64": fallbackTemplate,
      "Right_WSQImageSize": rightBase64.length,
      "Right_WSQImage": rightBase64,
      "Right_BMPBase64": rightBase64,
    };
  }

  Map<String, dynamic> _buildStudentSyncReport(Map<String, dynamic> student,
      {String? operatorId, String? examId, String? shiftId, String? centerId}) {
    String livePhoto = _cleanBase64(student['livePhotoBase64']);
    String rightThumb = _cleanBase64(student['rightThumbBase64']);
    String leftThumb = _cleanBase64(student['leftThumbBase64']);
    Map<String, dynamic> bData = _buildBiometricDataMap(student);

    return {
      // Exact API structure requested by USER:
      "studentId": student['id'] ?? student['_id'] ?? "",
      "photo": livePhoto,
      "left_thumbnail": leftThumb,
      "right_thumbnail": rightThumb,
      "biometricData": bData,
      "attendanceTime":
          student['attendanceTime'] ?? DateTime.now().toIso8601String(),
      "biometricTime":
          student['biometricTime'] ?? DateTime.now().toIso8601String(),
      "operatorId": operatorId ?? student['operatorId']?.toString() ?? "",

      // Legacy/Demographic details to prevent backend validation errors if any
      "applicationId": student['applicationId'] ?? "",
      "rollno": student['rollNo'] ?? student['rollno'] ?? "",
      "name": student['name'] ?? "",
      "fatherName": student['fatherName'] ?? "",
      "motherName": student['motherName'] ?? "",
      "email": student['email'] ?? "",
      "mobile": student['mobile'] ?? "",
      "address": student['address'] ?? "",
      "examId": student['examId'] ?? examId ?? "",
      "examName": student['examName'] ?? student['exam_name'] ?? examName.value,
      "shiftId": student['shiftId'] ?? shiftId ?? "",
      "shiftName": student['shiftName'] ?? "",
      "shiftStart": student['shiftStart'] ?? "",
      "shiftEnd": student['shiftEnd'] ?? "",
      "centerId": student['centerId'] ?? centerId ?? "",
      "centerName": student['centerName'] ?? centerName.value,
      "centerCode": student['centerCode'] ?? centerCode.value,
      "centerState": student['centerState'] ?? "",
      "centerDistrict": student['centerDistrict'] ?? "",
      "leftThumbnail": leftThumb,
      "rightThumbnail": rightThumb,
      "biometricTemplate":
          student['biometricTemplate'] ?? (bData['TemplateBase64'] ?? ""),
    };
  }

  // Ensure NotificationService is imported (wait, we need to add import at the top of the file)
  Future<void> backgroundSync() async {
    try {
      var box = Hive.box('candidates_box');
      final List allIndices = [];
      final List<Map<String, dynamic>> presentCandidates = [];

      for (int i = 0; i < box.length; i++) {
        var item = Map<String, dynamic>.from(box.getAt(i) as Map);
        if (item['attendanceStatus'] == true && item['syncStatus'] != true) {
          presentCandidates.add(item);
          allIndices.add(i);
        }
      }

      if (presentCandidates.isEmpty) return;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? operatorId = prefs.getString('operator_id_db') ??
          prefs.getString('operator_id') ??
          prefs.getString('id');
      String? examId = prefs.getString('exam_id');
      String? shiftId = prefs.getString('shift_id');
      String? centerId = prefs.getString('center_id');

      for (int i = 0; i < presentCandidates.length; i++) {
        int percentage = ((i) / presentCandidates.length * 100).toInt();
        await NotificationService()
            .showProgressNotification(i, presentCandidates.length, percentage);

        var student = presentCandidates[i];
        int hiveIndex = allIndices[i];

        Map<String, dynamic> studentReport = _buildStudentSyncReport(
          student,
          operatorId: operatorId,
          examId: examId,
          shiftId: shiftId,
          centerId: centerId,
        );

        Map<String, dynamic> payload = {
          "attendance_data": [studentReport]
        };

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
            student['syncStatus'] = true;
            student['syncFailed'] = false;
            await box.putAt(hiveIndex, student);
            print("🟢 Background sync success for ${student['name']}");
          } else {
            student['syncFailed'] = true;
            await box.putAt(hiveIndex, student);
            print(
                "🔴 Background sync failed for ${student['name']}: ${response.statusCode} - ${response.body}");
          }
        } catch (e) {
          student['syncFailed'] = true;
          await box.putAt(hiveIndex, student);
          print("🔴 Background sync exception for ${student['name']}: $e");
        }
      }

      await NotificationService().showSuccessNotification();
    } catch (e) {
      print("Background sync failed: $e");
    }
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
        isLoading.value = false;
        Get.snackbar("All Synced", "No pending attendance data to upload.",
            backgroundColor: Colors.blueAccent, colorText: Colors.white);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      String? operatorId = prefs.getString('operator_id_db') ??
          prefs.getString('operator_id') ??
          prefs.getString('id');
      String? examId = prefs.getString('exam_id');
      String? shiftId = prefs.getString('shift_id');
      String? centerId = prefs.getString('center_id');

      int successCount = 0;
      int failCount = 0;

      print("--- STARTING SEQUENTIAL SYNC ---");

      // Sync one-by-one to avoid "413 Request Entity Too Large"
      for (int i = 0; i < presentCandidates.length; i++) {
        var student = presentCandidates[i];
        int hiveIndex = allIndices[i];

        String livePhoto = _cleanBase64(student['livePhotoBase64']);
        String rightThumb = _cleanBase64(student['rightThumbBase64']);
        String leftThumb = _cleanBase64(student['leftThumbBase64']);

        print(
            "Syncing student: ${student['name']} (${i + 1}/${presentCandidates.length})");
        print("  - Live Photo Size: ${_formatBase64Size(livePhoto)}");
        print("  - Right Thumb Size: ${_formatBase64Size(rightThumb)}");
        print("  - Left Thumb Size: ${_formatBase64Size(leftThumb)}");

        Map<String, dynamic> studentReport = _buildStudentSyncReport(
          student,
          operatorId: operatorId,
          examId: examId,
          shiftId: shiftId,
          centerId: centerId,
        );

        Map<String, dynamic> payload = {
          "attendance_data": [studentReport]
        };

        print(
            "Syncing student: ${student['name']} (${i + 1}/${presentCandidates.length})");

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
            student['syncFailed'] = false;
            await box.putAt(hiveIndex, student);
            print("🟢 Sync success for ${student['name']}");
          } else {
            failCount++;
            student['syncFailed'] = true;
            await box.putAt(hiveIndex, student);
            print(
                "🔴 Failed for ${student['name']}: ${response.statusCode} - ${response.body}");
          }
        } catch (e) {
          failCount++;
          student['syncFailed'] = true;
          await box.putAt(hiveIndex, student);
          print("🔴 Error syncing ${student['name']}: $e");
        }
      }

      print("--- SYNC COMPLETED ---");
      print("Success: $successCount, Failed: $failCount");

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
