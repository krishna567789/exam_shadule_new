import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:exam_shadule_new/services/socket_service.dart';

class DownloadController extends GetxController {
  Database? _database;
  final RxString centerCode = ''.obs;
  final RxString centerName = ''.obs;
  final RxString selectedShift = ''.obs;
  final RxDouble downloadProgress = 0.0.obs;
  final RxBool isDownloading = false.obs;
  final RxInt totalStudents = 0.obs;
  final RxString shift = ''.obs;
  final RxString timing = ''.obs;
  final RxString shiftStart = ''.obs;
  final RxString shiftEnd = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getStoredSessionData();
    _initDatabase();
    countAllStudents();
  }

  Future<void> getStoredSessionData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    centerCode.value = prefs.getString('center_code') ?? "No Code Found";
    centerName.value = prefs.getString('center_name') ?? "No Name Found";
    shiftStart.value = prefs.getString('shift_start_time') ?? "";
    shiftEnd.value = prefs.getString('shift_end_time') ?? "";
    shift.value = prefs.getString('shift') ?? "Shift 1";
  }

  Future<void> _initDatabase() async {
    final databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'students_details.db');
    _database = await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE shifts(id INTEGER PRIMARY KEY, name TEXT, father_name TEXT, mother_name TEXT,"
              " email TEXT, mobile TEXT, address TEXT, rollno TEXT, examdate TEXT, shift TEXT, "
              "timing TEXT,state TEXT,district TEXT,center_name TEXT,center_code TEXT, photo TEXT, thumbnail TEXT, created_at TEXT, updated_at TEXT)",
        );
      },
      version: 1,
    );
  }

  Future<void> ensureDatabaseInitialized() async {
    if (_database == null) {
      await _initDatabase();
    }
  }

  Future<void> countAllStudents() async {
    var box = Hive.box('candidates_box');
    if (box.isNotEmpty) {
      totalStudents.value = box.length;
      return;
    }

    await ensureDatabaseInitialized();
    final db = _database;
    final countResult = await db?.rawQuery('SELECT COUNT(*) as total FROM shifts');
    if (countResult != null && countResult.isNotEmpty) {
      totalStudents.value = Sqflite.firstIntValue(countResult) ?? 0;
    }
  }

  Future<void> deleteStudentDetails() async {
    var box = Hive.box('candidates_box');
    await box.clear();

    await ensureDatabaseInitialized();
    if (_database != null) {
      await _database!.delete("shifts");
    }
    
    totalStudents.value = 0;
  }

  Future<void> fetchAndStoreData() async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      var response = await http.get(
        Uri.parse('https://bio.ubroapi.space/api/mobile/download'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      print("Download Response Status: ${response.statusCode}");
      print("Download Response Body (first 500): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        // ── Save operator / exam / shift / center from new API structure ──
        final operatorData = responseData['operator'];
        if (operatorData != null) {
          await prefs.setString('operator_id_db', operatorData['id'] ?? '');
          await prefs.setString('operator_email', operatorData['email'] ?? '');
          await prefs.setString('operator_role', operatorData['role'] ?? '');
          await prefs.setString('exam_id', operatorData['examId'] ?? '');
          await prefs.setString('shift_id', operatorData['shiftId'] ?? '');
          await prefs.setString('center_id', operatorData['centerId'] ?? '');
          await prefs.setString('center_code', operatorData['centerCode'] ?? '');
          await prefs.setString('center_name', operatorData['centerName'] ?? '');
        }

        final examData = responseData['exam'];
        if (examData != null) {
          await prefs.setString('exam_id', examData['id'] ?? prefs.getString('exam_id') ?? '');
          await prefs.setString('exam_name', examData['examName'] ?? '');
        }

        final shiftData = responseData['shift'];
        if (shiftData != null) {
          await prefs.setString('shift_id', shiftData['id'] ?? prefs.getString('shift_id') ?? '');
          await prefs.setString('shift', shiftData['shift'] ?? '');
          await prefs.setString('shift_start_time', shiftData['shiftStart'] ?? '');
          await prefs.setString('shift_end_time', shiftData['shiftEnd'] ?? '');
          shiftStart.value = shiftData['shiftStart'] ?? '';
          shiftEnd.value = shiftData['shiftEnd'] ?? '';
          shift.value = shiftData['shift'] ?? '';
        }

        final centerData = responseData['center'];
        if (centerData != null) {
          await prefs.setString('center_id', centerData['id'] ?? prefs.getString('center_id') ?? '');
          await prefs.setString('center_name', centerData['centerName'] ?? '');
          await prefs.setString('center_code', centerData['centerCode'] ?? '');
          await prefs.setString('center_state', centerData['centerState'] ?? '');
          await prefs.setString('center_district', centerData['centerDistrict'] ?? '');
          if (centerData['centerCapacity'] != null) {
            await prefs.setInt('center_capacity', centerData['centerCapacity']);
          }
          centerCode.value = centerData['centerCode'] ?? centerCode.value;
          centerName.value = centerData['centerName'] ?? centerName.value;
        }

        // ── Save socket info for real‑time updates ──
        final socketInfo = responseData['socket'];
        if (socketInfo != null) {
          await prefs.setString('socket_room', socketInfo['room'] ?? '');
          await prefs.setString('socket_event', socketInfo['event'] ?? 'attendance-completed');
          // Initialize SocketService and join the room
          try {
            // Ensure the service is registered only once
            if (!Get.isRegistered<SocketService>()) {
              Get.put(SocketService());
            }
            await SocketService.to.connectAndJoinRoom(
              room: socketInfo['room'] ?? '',
              event: socketInfo['event'] ?? 'attendance-completed',
              token: token ?? '',
            );
          } catch (e) {
            print('[DownloadController] Socket init error: $e');
          }
        }

        // Also persist downloadInfo stats for reference
        final downloadInfo = responseData['downloadInfo'];
        if (downloadInfo != null) {
          await prefs.setInt('total_students', downloadInfo['totalStudents'] ?? 0);
        }

        List<dynamic> candidates = [];
        if (responseData['students'] != null) {
          candidates = responseData['students'];
        } else if (responseData['data'] != null) {
          candidates = responseData['data'];
        }

        if (candidates.isEmpty) {
          Get.snackbar("Info", "No candidates found for this session.");
          isDownloading.value = false;
          return;
        }

        var box = Hive.box('candidates_box');
        await box.clear();

        List<Map<String, dynamic>> studentList = candidates.map((e) => Map<String, dynamic>.from(e)).toList();
        await box.addAll(studentList);
        downloadProgress.value = 1.0;
        totalStudents.value = box.length;

        Get.snackbar(
          "Success",
          "Downloaded ${box.length} candidates successfully.",
          backgroundColor: Colors.greenAccent,
        );

        // Cache images in background without blocking session setup
        _cacheImagesInBackground(studentList);
      } else {
        Get.snackbar("Error", "Failed to download data: ${response.reasonPhrase}",
            backgroundColor: Colors.redAccent, colorText: Colors.white);
      }
    } catch (e) {
      print("Download Error: $e");
      Get.snackbar("Error", "An error occurred: $e",
          backgroundColor: Colors.redAccent, colorText: Colors.white);
    } finally {
      isDownloading.value = false;
    }
  }

  void _cacheImagesInBackground(List<Map<String, dynamic>> candidates) async {
    try {
      var box = Hive.box('candidates_box');
      for (int i = 0; i < candidates.length; i++) {
        var student = Map<String, dynamic>.from(candidates[i]);
        bool modified = false;

        if (student['photo'] != null && student['photo'].toString().startsWith('http')) {
          String imageName = 'student_${student['rollNo'] ?? student['id']}';
          String? localPath = await getBitmapFromNetwork(student['photo'], imageName);
          if (localPath != null) {
            student['localPhotoPath'] = localPath;
            modified = true;
          }
        }

        if (student['thumbnail'] != null && student['thumbnail'].toString().startsWith('http')) {
          String thumbName = 'thumb_${student['rollNo'] ?? student['id']}';
          String? localThumb = await getBitmapFromNetwork(student['thumbnail'], thumbName);
          if (localThumb != null) {
            student['localThumbPath'] = localThumb;
            modified = true;
          }
        }

        if (student['livePhoto'] != null && student['livePhoto'].toString().startsWith('http')) {
          String imageName = 'live_photo_${student['rollNo'] ?? student['id']}';
          String? localPath = await getBitmapFromNetwork(student['livePhoto'], imageName);
          if (localPath != null) {
            student['localLivePhotoPath'] = localPath;
            modified = true;
          }
        }

        if (student['leftThumb'] != null && student['leftThumb'].toString().startsWith('http')) {
          String thumbName = 'left_thumb_${student['rollNo'] ?? student['id']}';
          String? localThumb = await getBitmapFromNetwork(student['leftThumb'], thumbName);
          if (localThumb != null) {
            student['localLeftThumbPath'] = localThumb;
            modified = true;
          }
        }

        if (student['rightThumb'] != null && student['rightThumb'].toString().startsWith('http')) {
          String thumbName = 'right_thumb_${student['rollNo'] ?? student['id']}';
          String? localThumb = await getBitmapFromNetwork(student['rightThumb'], thumbName);
          if (localThumb != null) {
            student['localRightThumbPath'] = localThumb;
            modified = true;
          }
        }

        if (modified && i < box.length) {
          await box.putAt(i, student);
        }
      }
    } catch (e) {
      print("Background image cache completed: $e");
    }
  }

  Future<String?> getBitmapFromNetwork(String imageUrl, String imageName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final image = img.decodeImage(response.bodyBytes);
        if (image != null) {
          final bytes = Uint8List.fromList(img.encodePng(image));
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$imageName.png';
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          return filePath;
        }
      }
    } catch (e) {
      print("Error downloading image: $e");
    }
    return null;
  }
}
