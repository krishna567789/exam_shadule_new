import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

class StorageService extends GetxService {
  static StorageService get to {
    try {
      return Get.find<StorageService>();
    } catch (e) {
      print("CRITICAL: StorageService not found in GetX context!");
      rethrow;
    }
  }

  late SharedPreferences _prefs;

  Future<StorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    print("StorageService: SharedPreferences initialized.");
    return this;
  }

  // --- STRICTLY PRESERVING EXISTING KEYS ---
  static const String keyToken = 'token';
  static const String keyOperatorEmail = 'operator_email';
  static const String keyLoginOperatorId = 'login_operator_id';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyCenterName = 'center_name';
  static const String keyCenterCode = 'center_code';
  static const String keyExamName = 'exam_name';
  static const String keyShiftStartTime = 'shift_start_time';
  static const String keyShiftEndTime = 'shift_end_time';
  static const String keyCenterCapacity = 'center_capacity';
  static const String keyIsProfileCompleted = 'is_profile_completed';
  static const String keyOperatorIdDb = 'operator_id_db';
  static const String keyOperatorName = 'operator_name';
  static const String keyFatherName = 'father_name';
  static const String keyOperatorPhone = 'operator_phone';
  static const String keyOperatorCityState = 'operator_city_state';
  static const String keyShift = 'shift';
  static const String keyGlobalTotal = 'global_total';
  static const String keyGlobalPresent = 'global_present';
  static const String keyGlobalAbsent = 'global_absent';

  // --- TOKEN ---
  String? getToken() => _prefs.getString(keyToken);
  Future<bool> saveToken(String token) => _prefs.setString(keyToken, token);

  // --- OPERATOR ---
  String? getOperatorEmail() => _prefs.getString(keyOperatorEmail);
  Future<bool> saveOperatorEmail(String email) => _prefs.setString(keyOperatorEmail, email);
  
  String? getLoginOperatorId() => _prefs.getString(keyLoginOperatorId);
  Future<bool> saveLoginOperatorId(String id) => _prefs.setString(keyLoginOperatorId, id);

  // --- SESSION ---
  bool isLoggedIn() => _prefs.getBool(keyIsLoggedIn) ?? false;
  Future<bool> setLoggedIn(bool value) => _prefs.setBool(keyIsLoggedIn, value);

  // --- GENERIC PREFS ACCESS ---
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<void> clearAll() async {
    await _prefs.clear();
    var box = Hive.box('candidates_box');
    await box.clear();
  }
}
