import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class AttendanceController {
  static Database? _database;

  // Initialize the database
  static Future<Database?> initDatabase() async {
    if (_database != null) return _database;

    final databasePath = await getApplicationDocumentsDirectory();
    final path = join(databasePath.path, 'students_details.db');
    _database = await openDatabase(
      path,
      onCreate: (db, version) async {
        await db.execute(
          "CREATE TABLE shifts(id INTEGER PRIMARY KEY, name TEXT, father_name TEXT, mother_name TEXT,"
              " email TEXT, mobile TEXT, address TEXT, rollno TEXT, examdate TEXT, shift TEXT, "
              "timing TEXT, state TEXT, district TEXT, center_name TEXT, center_code TEXT, photo TEXT, thumbnail TEXT, created_at TEXT, updated_at TEXT)",
        );
      },
      version: 1,
    );
    return _database;
  }

  // Search student by roll number
  static Future<Map<String, dynamic>?> searchStudent(String rollNumber) async {
    final db = await initDatabase();
    if (db == null) return null;

    final List<Map<String, dynamic>> result = await db.query(
      'shifts',
      where: 'rollno LIKE ?',
      whereArgs: ['%$rollNumber'],
    );

    if (result.isNotEmpty) {
      return result.first;
    } else {
      return null;
    }
  }
}
