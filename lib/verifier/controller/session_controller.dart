import 'dart:convert';
import 'package:get/get.dart';
import '../models/verifier_models.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../../controller/base_controller.dart';

/// Holds the logged-in verifier's session (identity + assigned exam/center).
/// Loaded from `/mobile/me` on cold start and after login. The exam/center
/// are fixed by the backend — the app must never let the verifier switch them.
class VerifierSessionController extends BaseController {
  static VerifierSessionController get to => Get.find<VerifierSessionController>();

  final _session = Rxn<VerifierSession>();
  VerifierSession? get session => _session.value;

  bool get profileCompleted => _session.value?.profileCompleted ?? false;
  String get examName => _session.value?.examName ?? '';
  String get centerName => _session.value?.centerName ?? '';
  String get centerCode => _session.value?.centerCode ?? '';
  String get verifierName => _session.value?.profile.name ?? '';
  String get verifierId =>
      _session.value?.verifierId ?? VerifierStorageService.to.getVerifierId() ?? '';

  void cacheFromSession(VerifierSession s) {
    _session.value = s;
    persist(s);
  }

  /// Loads /mobile/me. Returns the parsed session, or null on failure.
  Future<VerifierSession?> loadMe() async {
    try {
      final res = await VerifierApiService.to.get(VerifierApiService.urlMe);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          final data = body['data'];
          if (data is Map<String, dynamic>) {
            final s = VerifierSession.fromJson(data);
            _session.value = s;
            persist(s);
            return s;
          }
        }
      }
    } catch (e) {
      print("VerifierSessionController.loadMe error: $e");
    }
    return null;
  }

  void persist(VerifierSession s) {
    final st = VerifierStorageService.to;
    if (s.verifierId.isNotEmpty) st.saveVerifierId(s.verifierId);
    st.setString(VerifierStorageService.keyVerifierDbId, s.id);
    st.setString(VerifierStorageService.keyExamId, s.examId);
    st.setString(VerifierStorageService.keyExamName, s.examName);
    st.setString(VerifierStorageService.keyExamCode, s.examCode);
    st.setString(VerifierStorageService.keyCenterId, s.centerId);
    st.setString(VerifierStorageService.keyCenterCode, s.centerCode);
    st.setString(VerifierStorageService.keyCenterName, s.centerName);
    st.setString(VerifierStorageService.keyCenterDistrict, s.centerDistrict);
    st.setString(VerifierStorageService.keyCenterState, s.centerState);
    st.setBool(VerifierStorageService.keyIsProfileCompleted, s.profileCompleted);
    final p = s.profile;
    if (p.name.isNotEmpty) st.setString(VerifierStorageService.keyVerifierName, p.name);
    if (p.fatherName.isNotEmpty) {
      st.setString(VerifierStorageService.keyVerifierFatherName, p.fatherName);
    }
    if (p.mobileNumber.isNotEmpty) {
      st.setString(VerifierStorageService.keyVerifierPhone, p.mobileNumber);
    }
    if (p.email.isNotEmpty) st.setString(VerifierStorageService.keyVerifierEmail, p.email);
    if (p.address.isNotEmpty) st.setString(VerifierStorageService.keyVerifierAddress, p.address);
    if (p.city.isNotEmpty || p.state.isNotEmpty) {
      st.setString(VerifierStorageService.keyVerifierCityState, "${p.city}, ${p.state}");
    }
    if (p.photo.isNotEmpty) st.setString(VerifierStorageService.keyVerifierPhoto, p.photo);
    if (p.aadharFront.isNotEmpty) {
      st.setString(VerifierStorageService.keyVerifierAadharFront, p.aadharFront);
    }
    if (p.aadharBack.isNotEmpty) {
      st.setString(VerifierStorageService.keyVerifierAadharBack, p.aadharBack);
    }
  }
}
