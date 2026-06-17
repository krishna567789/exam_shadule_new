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
import 'package:exam_shadule_new/models/download_model/download_model.dart';

class DownloadController extends GetxController {
  Database? _database;
  String centerCode = '';
  String centerName = '';
  var selectedShift = ''.obs;
  var downloadProgress = 0.0.obs;
  var imageBytes = Rx<Uint8List?>(null);
  var isDownloading = false.obs;
  var totalStudents = 0.obs;
  var shift = ''.obs;
  var timing = ''.obs;

  @override
  void onInit() {
    super.onInit();
    getCode();
    _initDatabase(); // Ensure database is initialized
  }

  Future<void> getCode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    centerCode = prefs.getString('center_code') ?? "No Code Found";
    centerName = prefs.getString('center_name') ?? "No Name Found";
    update();
  }

  // Ensure proper initialization of the database
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
    print("Database initialized successfully");
  }

  // Function to ensure the database is initialized before operations
  Future<void> ensureDatabaseInitialized() async {
    if (_database == null) {
      print("Database not initialized. Initializing now...");
      await _initDatabase();
    }
  }

  Future<void> countAllStudents() async {
    await ensureDatabaseInitialized(); // Ensure database is initialized before use
    final db = _database;
    final countResult = await db?.rawQuery('SELECT COUNT(*) as total FROM shifts');
    if (countResult != null && countResult.isNotEmpty) {
      totalStudents.value = Sqflite.firstIntValue(countResult) ?? 0;
      print("Total Students Count: ${totalStudents.value}");
    } else {
      totalStudents.value = 0;
      print("No records found");
    }

    // Query for shift and timing
    final details = await db?.rawQuery('SELECT shift, timing FROM shifts LIMIT 1');
    if (details != null && details.isNotEmpty) {
      shift.value = details[0]['shift']?.toString() ?? '';
      timing.value = details[0]['timing']?.toString() ?? '';
    } else {
      shift.value = '';
      timing.value = '';
    }
  }

  Future<void> deleteStudentDetails() async {
    await ensureDatabaseInitialized(); // Ensure database is initialized before use
    if (_database == null) {
      print("Database not initialized");
      return;
    }
    try {
      final db = _database;
      int count = await db!.delete("shifts");
      print("Deleted $count records from shifts table");
    } catch (e) {
      print("Error deleting records: $e");
    }
  }



  Future<void> fetchAndStoreData() async {
    if (selectedShift.value.isEmpty) {
      Get.snackbar(
          "Error", "Please select a shift", backgroundColor: Colors.red);
      return;
    }
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      final response = await http.get(Uri.parse(
          'https://bio.ubrosoft.com/api/students/shift/Shift ${selectedShift
              .value}')
      );
      print("API URL: ${response.request?.url} | Response: ${response.body}");
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        // await countRecordsWithShiftsAndTimings(selectedShift.value);
        for (int i = 0; i < data.length; i++) {
          var studentData = data[i];
          var photoUrl = studentData['photo'];
          String imageName = 'student_${studentData['rollno']}';
          await getBitmapFromNetwork(photoUrl, imageName);
          await _storeDataLocally([studentData]);
          downloadProgress.value =
              (i + 1) / data.length;
        }
        Get.snackbar("Success", "Download Completed Successfully",
            backgroundColor: Colors.green);
      } else {
        Get.snackbar("Error",
            "Failed to fetch data. Status Code: ${response.statusCode}",
            backgroundColor: Colors.red);
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred while downloading data",
          backgroundColor: Colors.red);
      print('Error: $e');
    } finally {
      isDownloading.value = false;
    }
  }

// Function to download, decode, and save an image locally
  Future<String?> getBitmapFromNetwork(String imageUrl, String imageName) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final image = img.decodeImage(response.bodyBytes);
        if (image != null) {
          final bytes = Uint8List.fromList(img.encodePng(image));
          final directory = await getApplicationDocumentsDirectory();
          final filePath = '${directory.path}/$imageName.png'; // Use unique name for each image
          final file = File(filePath);
          await file.writeAsBytes(bytes);
          print("Image saved successfully at $filePath");
          return filePath;
        }
      }
    } catch (e) {
      print("Error: $e");
    }
    return null;
  }

  Future<void> _storeDataLocally(List<dynamic> data) async {
    final db = _database;
    if (db == null) return;

    for (int i = 0; i < data.length; i++) {
      var studentData = data[i];
      var photoUrl = studentData['photo'];
      String imageName = 'student_${studentData['rollno']}';
      String? imagePath = await getBitmapFromNetwork(photoUrl, imageName);
      if (imagePath != null) {
        studentData['photo'] = imagePath;
      }
      await db.insert(
        'shifts',
        StudentDetailsModel.fromJson(studentData).toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await countAllStudents();  // Ensure this is called after all inserts are complete
  }


}

