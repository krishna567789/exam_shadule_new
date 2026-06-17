import 'dart:io' as io;
import 'package:exam_shadule_new/models/device_model/user_profile_model.dart';
import 'package:get/get.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class UserProfileHelper extends GetxController {
  static final UserProfileHelper _instance = UserProfileHelper.internal();
  factory UserProfileHelper() => _instance;

  static Database? _db;

  UserProfileHelper.internal();

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await initDb();
    return _db!;
  }

  // Initialize the database
  Future<Database> initDb() async {
    io.Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'users_profile.db');
    var theDb = await openDatabase(path, version: 1, onCreate: (Database db, int version) async {
      await db.execute(''' 
        CREATE TABLE users_profile (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          name TEXT,
          father_name TEXT,
          mobile_number  TEXT,
          email TEXT,
          address TEXT,
          center_name TEXT,
          center_code TEXT,
          photo TEXT,
          aadhar_front TEXT,
          aadhar_back TEXT
        )
      ''');
    });
    return theDb;
  }

  // Insert user profile into the database
  Future<void> storeUserProfile(UserProfileModel userProfile) async {
    var dbClient = await db;
    try {
      await dbClient.insert(
        'users_profile',
        userProfile.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      // print("User profile inserted successfully");
    } catch (e) {
      print("Error inserting user profile: $e");
    }
  }

  // Retrieve user profile from the database by ID
  Future<UserProfileModel?> getUserProfile(int id) async {
    var dbClient = await db;
    try {
      List<Map<String, dynamic>> maps = await dbClient.query(
        'user_profile',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (maps.isNotEmpty) {
        return UserProfileModel.fromJson(maps.first);
      }
    } catch (e) {
      print("Error retrieving user profile: $e");
    }
    return null;
  }
  Future<void> deleteUsersProfile() async {
    final dbs = await db;
    await dbs.delete("users_profile");
  }

  // Update user profile in the database
  // Future<void> updateUserProfile(UserProfileModel userProfile) async {
  //   var dbClient = await db;
  //   try {
  //     await dbClient.update(
  //       'user_profile',
  //       userProfile.toJson(),
  //       where: 'id = ?',
  //       whereArgs: [userProfile.id],
  //     );
  //     print("User profile updated successfully");
  //   } catch (e) {
  //     print("Error updating user profile: $e");
  //   }
  // }

  // Delete user profile from the database
  Future<void> deleteUserProfile(int id) async {
    var dbClient = await db;
    try {
      await dbClient.delete(
        'user_profile',
        where: 'id = ?',
        whereArgs: [id],
      );
      print("User profile deleted successfully");
    } catch (e) {
      print("Error deleting user profile: $e");
    }
  }
}
