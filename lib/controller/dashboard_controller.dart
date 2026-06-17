import 'dart:io';
import 'package:exam_shadule_new/controller/device_local_db/user_profile_helper.dart';
import 'package:exam_shadule_new/controller/download_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'device_local_db/attendance_helper.dart';

class DashboardController extends GetxController {
  var isLoading = false.obs;
  var centerName = ''.obs;
  var centerCode = ''.obs;

  void getStoredData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    centerCode.value = prefs.getString('center_code') ?? 'No Code Found';
    centerName.value = prefs.getString('center_name') ?? 'No Name Found';
  }

  String _getXsrfTokenFromCookie(String cookieHeader) {
    final xsrfMatch = RegExp(r'XSRF-TOKEN=([^;]+);').firstMatch(cookieHeader);
    if (xsrfMatch != null && xsrfMatch.groupCount >= 1) {
      return Uri.decodeComponent(xsrfMatch.group(1)!);
    }
    return '';
  }

  Future<XFile?> compressImage(File file) async {
    final dir = await getTemporaryDirectory();
    final targetPath =
        p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.jpg');

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 40,
    );

    return result;
  }

  Future<void> sendAttendanceData() async {
    isLoading.value = true;

    final dbHelper = AttendanceHelper();
    final records = await dbHelper.fetchAllAttendanceData();

    if (records.isEmpty) {
      isLoading.value = false;
      Get.snackbar("No Records", "No attendance records found.",
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    try {
      final client = http.Client();

      final getResponse = await client.get(
          Uri.parse('https://bio.ubrosoft.com/api/attendance-reports'));
      print("GET API URL: ${getResponse.request?.url} | Response: ${getResponse.body}");

      final cookies = getResponse.headers['set-cookie'];
      final xsrfToken = _getXsrfTokenFromCookie(cookies ?? '');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://bio.ubrosoft.com/api/attendance-reports'),
      );

      request.headers.addAll({
        if (xsrfToken.isNotEmpty) 'X-XSRF-TOKEN': xsrfToken,
        if (cookies != null) 'Cookie': cookies,
        'Accept': 'application/json',
      });

      for (int i = 0; i < records.length; i++) {
        var record = records[i];

        request.fields['attendance_data[$i][name]'] =
            record['name']?.toString() ?? '';
        request.fields['attendance_data[$i][father_name]'] =
            record['father_name']?.toString() ?? '';
        request.fields['attendance_data[$i][mother_name]'] =
            record['mother_name']?.toString() ?? '';
        request.fields['attendance_data[$i][email]'] =
            record['email']?.toString() ?? '';
        request.fields['attendance_data[$i][mobile]'] =
            record['mobile']?.toString() ?? '';
        request.fields['attendance_data[$i][address]'] =
            record['address']?.toString() ?? '';
        request.fields['attendance_data[$i][rollno]'] =
            record['rollno']?.toString() ?? '';
        request.fields['attendance_data[$i][examdate]'] =
            record['examdate']?.toString() ?? '';
        request.fields['attendance_data[$i][shift]'] =
            record['shift']?.toString() ?? '';
        request.fields['attendance_data[$i][timing]'] =
            record['timing']?.toString() ?? '';
        request.fields['attendance_data[$i][state]'] =
            record['state']?.toString() ?? '';
        request.fields['attendance_data[$i][district]'] =
            record['district']?.toString() ?? '';
        request.fields['attendance_data[$i][center_name]'] =
            record['center_name']?.toString() ?? '';
        request.fields['attendance_data[$i][center_code]'] =
            record['center_code']?.toString() ?? '';

        // Compress and attach photo
        if (record['photo'] != null &&
            File(record['photo'].toString()).existsSync()) {
          final original = File(record['photo'].toString());
          final compressed = await compressImage(original);
          if (compressed != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'attendance_data[$i][photo]',
              compressed.path,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        }

        // Compress and attach thumbnail
        if (record['thumbnail'] != null &&
            File(record['thumbnail'].toString()).existsSync()) {
          final original = File(record['thumbnail'].toString());
          final compressed = await compressImage(original);
          if (compressed != null) {
            request.files.add(await http.MultipartFile.fromPath(
              'attendance_data[$i][thumbnail]',
              compressed.path,
              contentType: MediaType('image', 'jpeg'),
            ));
          }
        }
      }

      final streamedResponse = await client.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      print("POST API URL: ${response.request?.url} | Response: ${response.body}");

      if (response.statusCode == 200) {
        print('✅ Upload successful: ${response.body}');
        await DownloadController().deleteStudentDetails();
        await AttendanceHelper().deleteAllEmployees();
        await UserProfileHelper().deleteUsersProfile();
        Get.snackbar("Upload Success", "All attendance records uploaded.",
            backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        print('❌ Upload failed with status: ${response.statusCode}');
        print('⛔ Response body: ${response.body}');
        Get.snackbar("Upload Failed", response.body,
            backgroundColor: Colors.red, colorText: Colors.white);
      }
    } catch (e) {
      print('⚠️ Exception occurred: $e');
      Get.snackbar("Error", "Upload failed: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      isLoading.value = false;
    }
  }
}
