import 'package:exam_shadule_new/models/attendance_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AttendanceHelper extends GetxController {
 var totalPresentStudents = 0.obs;
 static final AttendanceHelper _instance = AttendanceHelper.internal();
  factory AttendanceHelper() => _instance;
  static Database? _db;
  AttendanceHelper.internal();



  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'student_attendance.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
         '''CREATE TABLE attendance_data(
          id INTEGER PRIMARY KEY,
          name TEXT,
          father_name TEXT,
          mother_name TEXT,
          email TEXT,
          mobile TEXT,
          address TEXT,
          rollno TEXT,
          examdate TEXT,
          shift TEXT,
          timing TEXT,
          state TEXT,
          district TEXT,
          center_name TEXT,
          center_code TEXT,
          photo TEXT,
          thumbnail TEXT
        )'''
        );
        print("✅ attendance_data table created");
      },
    );
  }

  Future<void> countAllStudents() async {
    final dbs = await db;
    final countResult = await dbs.rawQuery('SELECT COUNT(*) as total FROM attendance_data');
    totalPresentStudents.value = Sqflite.firstIntValue(countResult) ?? 0;
  }


  Future<void> storeUserProfile(AttendanceModel attendanceModel) async {
    var dbClient = await db;

    try {
      print("🔍 Checking if user already exists...");

      List<Map<String, dynamic>> existingUser = await dbClient.query(
        'attendance_data',
        where: 'rollno = ?',
        whereArgs: [attendanceModel.rollno],
      );
      if (existingUser.isNotEmpty) {
        print("⚠️ User already exists");
        Get.snackbar("Duplicate Entry", "You are already registered.",
            snackPosition: SnackPosition.TOP,backgroundColor: Colors.red);
        return;
      }
      print("Trying to insert into table attendance_data...");
      await dbClient.insert(
        'attendance_data',
        attendanceModel.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await countAllStudents();
      print("✅ Insert successful");
      Get.snackbar("Success", "User profile saved.",
          snackPosition: SnackPosition.TOP,colorText: Colors.white,backgroundColor: Colors.green);
    } catch (e) {
      print("❌ Error inserting user profile: $e");
      Get.snackbar("Error", "Failed to insert user.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<List<Map<String, Object?>>> fetchAllAttendanceData() async {
    final dbs = await db;
    return await dbs.query('attendance_data');
  }

  Future<void> deleteAllEmployees() async {
    final dbs = await db;
    await dbs.delete("attendance_data");
  }

}

