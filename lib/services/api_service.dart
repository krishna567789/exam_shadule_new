import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'storage_service.dart';

class ApiService extends GetxService {
  static ApiService get to => Get.find<ApiService>();

  // --- STRICTLY PRESERVING EXISTING URLS ---
  static const String baseUrl = "https://bio.ubroapi.space/api";
  
  static const String urlLogin = "$baseUrl/registrars/login";
  static const String urlCheckProfile = "$baseUrl/operator-users/profile/check";
  static const String urlDownload = "$baseUrl/mobile/download";
  static const String urlPhysicalAttendance = "$baseUrl/physical-attendance";

  Map<String, String> get _headers {
    String? token;
    try {
      token = StorageService.to.getToken();
    } catch (_) {
      // StorageService not initialized yet
    }
    
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String url, {Map<String, String>? queryParams}) async {
    String queryString = "";
    if (queryParams != null && queryParams.isNotEmpty) {
      queryString = "?" + queryParams.entries.map((e) => "${e.key}=${e.value}").join("&");
    }
    
    final uri = Uri.parse(url + queryString);
    print("API GET REQUEST: $uri");
    return await http.get(uri, headers: _headers);
  }

  Future<http.Response> post(String url, dynamic body) async {
    final uri = Uri.parse(url);
    print("API POST REQUEST: $uri");
    print("API BODY: ${json.encode(body)}");
    return await http.post(
      uri,
      headers: _headers,
      body: json.encode(body),
    );
  }

  // Helper for Multipart
  Future<http.MultipartRequest> multipartRequest(String url, {String method = 'POST'}) async {
    final request = http.MultipartRequest(method, Uri.parse(url));
    
    String? token;
    try {
      token = StorageService.to.getToken();
    } catch (_) {}

    request.headers.addAll({
      'Accept': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token',
    });
    return request;
  }
}
