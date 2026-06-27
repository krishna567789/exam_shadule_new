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

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
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

        for (int i = 0; i < candidates.length; i++) {
          var student = candidates[i];
          
          if (student['photo'] != null && student['photo'].toString().startsWith('http')) {
            String imageName = 'student_${student['rollNo'] ?? student['id']}';
            String? localPath = await getBitmapFromNetwork(student['photo'], imageName);
            if (localPath != null) {
              student['localPhotoPath'] = localPath;
            }
          }

          if (student['thumbnail'] != null && student['thumbnail'].toString().startsWith('http')) {
            String thumbName = 'thumb_${student['rollNo'] ?? student['id']}';
            String? localThumb = await getBitmapFromNetwork(student['thumbnail'], thumbName);
            if (localThumb != null) {
              student['localThumbPath'] = localThumb;
            }
          }
          
          await box.add(student);
          downloadProgress.value = (i + 1) / candidates.length;
        }

        totalStudents.value = box.length;
        Get.snackbar("Success", "Successfully downloaded ${box.length} candidates.",
            backgroundColor: Colors.greenAccent);
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
