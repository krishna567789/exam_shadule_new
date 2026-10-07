import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';

/// Persists the verifier session (token + assigned exam/center) and profile
/// details. All keys are namespaced `vse_*` so they never collide with the
/// operator console's storage inside the merged app.
class VerifierStorageService extends GetxService {
  static VerifierStorageService get to {
    try {
      return Get.find<VerifierStorageService>();
    } catch (e) {
      print("CRITICAL: VerifierStorageService not found in GetX context!");
      rethrow;
    }
  }

  late SharedPreferences _prefs;

  Future<VerifierStorageService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // --- Session ---
  static const String keyToken = 'vse_token';
  static const String keyIsLoggedIn = 'vse_is_logged_in';

  // --- Verifier identity ---
  static const String keyVerifierId = 'vse_verifier_id';
  static const String keyVerifierDbId = 'vse_verifier_db_id';
  static const String keyVerifierName = 'vse_verifier_name';
  static const String keyVerifierFatherName = 'vse_verifier_father_name';
  static const String keyVerifierPhone = 'vse_verifier_phone';
  static const String keyVerifierEmail = 'vse_verifier_email';
  static const String keyVerifierAddress = 'vse_verifier_address';
  static const String keyVerifierCityState = 'vse_verifier_city_state';
  static const String keyVerifierPhoto = 'vse_verifier_photo';
  static const String keyVerifierAadharFront = 'vse_verifier_aadhar_front';
  static const String keyVerifierAadharBack = 'vse_verifier_aadhar_back';

  // --- Assignment (fixed by backend, app must not switch center) ---
  static const String keyExamId = 'vse_exam_id';
  static const String keyExamName = 'vse_exam_name';
  static const String keyExamCode = 'vse_exam_code';
  static const String keyCenterId = 'vse_center_id';
  static const String keyCenterCode = 'vse_center_code';
  static const String keyCenterName = 'vse_center_name';
  static const String keyCenterDistrict = 'vse_center_district';
  static const String keyCenterState = 'vse_center_state';

  static const String keyIsProfileCompleted = 'vse_is_profile_completed';

  // --- TOKEN ---
  String? getToken() => _prefs.getString(keyToken);
  Future<bool> saveToken(String token) => _prefs.setString(keyToken, token);

  // --- LOGIN STATE ---
  bool isLoggedIn() => _prefs.getBool(keyIsLoggedIn) ?? false;
  Future<bool> setLoggedIn(bool value) => _prefs.setBool(keyIsLoggedIn, value);

  // --- GENERIC ---
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) => _prefs.setString(key, value);
  int? getInt(String key) => _prefs.getInt(key);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  // --- VERIFIER ---
  String? getVerifierId() => _prefs.getString(keyVerifierId);
  Future<bool> saveVerifierId(String id) => _prefs.setString(keyVerifierId, id);
  String? getVerifierName() => _prefs.getString(keyVerifierName);

  Future<void> clearAll() async {
    // Only wipe verifier-owned prefs; operator keys must survive verifier logout.
    for (final key in _prefs.getKeys().toList()) {
      if (key.startsWith('vse_')) {
        await _prefs.remove(key);
      }
    }
    await Hive.box('vse_pending_sync_box').clear();
  }
}
