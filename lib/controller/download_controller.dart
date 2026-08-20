import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'base_controller.dart';

class DownloadController extends BaseController {
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
    centerCode.value = StorageService.to.getString(StorageService.keyCenterCode) ?? "No Code Found";
    centerName.value = StorageService.to.getString(StorageService.keyCenterName) ?? "No Name Found";
    shiftStart.value = StorageService.to.getString(StorageService.keyShiftStartTime) ?? "";
    shiftEnd.value = StorageService.to.getString(StorageService.keyShiftEndTime) ?? "";
    shift.value = StorageService.to.getString(StorageService.keyShift) ?? "Shift 1";
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
    if (_database == null) await _initDatabase();
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
    if (_database != null) await _database!.delete("shifts");
    totalStudents.value = 0;
  }

  Future<void> fetchAndStoreData() async {
    try {
      isDownloading.value = true;
      downloadProgress.value = 0.0;

      final response = await ApiService.to.get(ApiService.urlDownload);

      print("Download Response Status: ${response.statusCode}");

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        // ── Save operator / exam / shift / center ──
        final op = responseData['operator'];
        if (op != null) {
          await StorageService.to.setString(StorageService.keyOperatorIdDb, op['id'] ?? '');
          await StorageService.to.setString(StorageService.keyOperatorEmail, op['email'] ?? '');
          await StorageService.to.setString('operator_role', op['role'] ?? '');
          await StorageService.to.setString('exam_id', op['examId'] ?? '');
          await StorageService.to.setString('shift_id', op['shiftId'] ?? '');
          await StorageService.to.setString('center_id', op['centerId'] ?? '');
          await StorageService.to.setString(StorageService.keyCenterCode, op['centerCode'] ?? '');
          await StorageService.to.setString(StorageService.keyCenterName, op['centerName'] ?? '');
        }

        final examData = responseData['exam'];
        if (examData != null) {
          await StorageService.to.setString('exam_id', examData['id'] ?? StorageService.to.getString('exam_id') ?? '');
          await StorageService.to.setString(StorageService.keyExamName, examData['examName'] ?? '');
        }

        final shiftData = responseData['shift'];
        if (shiftData != null) {
          await StorageService.to.setString('shift_id', shiftData['id'] ?? StorageService.to.getString('shift_id') ?? '');
          await StorageService.to.setString(StorageService.keyShift, shiftData['shift'] ?? '');
          await StorageService.to.setString(StorageService.keyShiftStartTime, shiftData['shiftStart'] ?? '');
          await StorageService.to.setString(StorageService.keyShiftEndTime, shiftData['shiftEnd'] ?? '');
          shiftStart.value = shiftData['shiftStart'] ?? '';
          shiftEnd.value = shiftData['shiftEnd'] ?? '';
          shift.value = shiftData['shift'] ?? '';
        }

        final centerData = responseData['center'];
        if (centerData != null) {
          await StorageService.to.setString('center_id', centerData['id'] ?? StorageService.to.getString('center_id') ?? '');
          await StorageService.to.setString(StorageService.keyCenterName, centerData['centerName'] ?? '');
          await StorageService.to.setString(StorageService.keyCenterCode, centerData['centerCode'] ?? '');
          await StorageService.to.setString('center_state', centerData['centerState'] ?? '');
          await StorageService.to.setString('center_district', centerData['centerDistrict'] ?? '');
          if (centerData['centerCapacity'] != null) {
            await StorageService.to.setInt(StorageService.keyCenterCapacity, centerData['centerCapacity']);
          }
          centerCode.value = centerData['centerCode'] ?? centerCode.value;
          centerName.value = centerData['centerName'] ?? centerName.value;
        }

        // ── Save socket info ──
        final socketInfo = responseData['socket'];
        if (socketInfo != null) {
          await StorageService.to.setString('socket_room', socketInfo['room'] ?? '');
          await StorageService.to.setString('socket_event', socketInfo['event'] ?? 'attendance-completed');
          try {
            if (!Get.isRegistered<SocketService>()) Get.put(SocketService());
            await SocketService.to.connectAndJoinRoom(
              room: socketInfo['room'] ?? '',
              event: socketInfo['event'] ?? 'attendance-completed',
              token: StorageService.to.getToken() ?? '',
            );
          } catch (e) {
            print('[DownloadController] Socket init error: $e');
          }
        }

        if (responseData['downloadInfo'] != null) {
          final info = responseData['downloadInfo'];
          await StorageService.to.setInt(StorageService.keyGlobalTotal, info['totalStudents'] ?? 0);
          await StorageService.to.setInt(StorageService.keyGlobalPresent, info['completed'] ?? 0);
          await StorageService.to.setInt(StorageService.keyGlobalAbsent, info['pending'] ?? 0);
          await StorageService.to.setInt('total_students', info['totalStudents'] ?? 0);
        }

        List<dynamic> candidates = responseData['students'] ?? responseData['data'] ?? [];

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

        showSuccess("Success", "Downloaded ${box.length} candidates successfully.");
        _cacheImagesInBackground(studentList);
      } else {
        showError("Failed to download data: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("Download Error: $e");
      showError("An error occurred: $e");
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

        Future<void> updateImg(String key, String localKey, String namePrefix) async {
           if (student[key] != null && student[key].toString().startsWith('http')) {
            String name = '${namePrefix}_${student['rollNo'] ?? student['id']}';
            String? localPath = await getBitmapFromNetwork(student[key], name);
            if (localPath != null) {
              student[localKey] = localPath;
              modified = true;
            }
          }
        }

        await updateImg('photo', 'localPhotoPath', 'student');
        await updateImg('thumbnail', 'localThumbPath', 'thumb');
        await updateImg('livePhoto', 'localLivePhotoPath', 'live_photo');
        await updateImg('leftThumb', 'localLeftThumbPath', 'left_thumb');
        await updateImg('rightThumb', 'localRightThumbPath', 'right_thumb');

        if (modified && i < box.length) await box.putAt(i, student);
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
