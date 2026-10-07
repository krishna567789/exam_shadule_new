import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'storage_service.dart';

/// VerifierApiService for the Verify Secure Exam (verifier) app.
///
/// All routes live under `https://bio.ubroapi.space/api/verifiers`.
/// After [login] the returned token is stored and automatically attached as
/// `Authorization: Bearer <token>` on every protected request.
class VerifierApiService extends GetxService {
  static VerifierApiService get to => Get.find<VerifierApiService>();

  static const String baseUrl = "https://bio.ubroapi.space";
  static const String apiPrefix = "$baseUrl/api/verifiers";

  // --- Auth / profile ---
  static const String urlLogin = "$apiPrefix/login";
  static const String urlMe = "$apiPrefix/mobile/me";
  static const String urlCheckProfile = "$apiPrefix/profile/check";
  static const String urlCreateProfile = "$apiPrefix/mobile/profile";

  // --- Data ---
  static const String urlDashboard = "$apiPrefix/mobile/dashboard";
  static const String urlCandidates = "$apiPrefix/mobile/candidates";
  static const String urlCandidateSearch = "$apiPrefix/mobile/candidates/search";

  // --- Verification / sync ---
  static const String urlSync = "$apiPrefix/mobile/sync";
  static String urlVerify(String candidateId) =>
      "$urlCandidates/$candidateId/verify";
  static String urlCandidateDetail(String candidateId) =>
      "$urlCandidates/$candidateId";

  Map<String, String> get _headers {
    String? token;
    try {
      token = VerifierStorageService.to.getToken();
    } catch (_) {
      // VerifierStorageService not registered yet
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Map<String, String> get _authHeadersOnly {
    final h = Map<String, String>.from(_headers);
    h.remove('Content-Type');
    return h;
  }

  Future<http.Response> get(String url, {Map<String, String>? queryParams}) async {
    Uri uri = Uri.parse(url);
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: {...uri.queryParameters, ...queryParams});
    }
    print("API GET REQUEST: $uri");
    return await http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String url, dynamic body) async {
    final uri = Uri.parse(url);
    print("API POST REQUEST: $uri");
    print("API BODY: ${json.encode(body)}");
    return await http.post(uri, headers: _headers, body: json.encode(body));
  }

  /// Builder for multipart uploads (verifier profile photo + aadhaar).
  Future<http.MultipartRequest> multipartRequest(String url) async {
    final request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(_authHeadersOnly);
    return request;
  }
}
