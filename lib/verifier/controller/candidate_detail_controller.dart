import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/candidate.dart';
import '../models/pending_verification.dart';
import '../services/api_service.dart';

import '../services/sync_service.dart';
import '../../controller/base_controller.dart';
import 'candidates_controller.dart';
import 'dashboard_controller.dart';
import '../../controller/device_info_controller.dart';

/// Candidate detail + verification submission.
///
/// Online:  POST /mobile/candidates/:id/verify
/// Offline: enqueue to Hive and later bulk-sync via /mobile/sync
class VerifierCandidateDetailController extends BaseController {
  static const _uuid = Uuid();

  final candidate = Rxn<Candidate>();
  final capturedLeftQuality = Rxn<int>();
  final capturedRightQuality = Rxn<int>();
  final capturedLeftImage = Rxn<Uint8List>();
  final capturedRightImage = Rxn<Uint8List>();
  final livePhotoPath = Rx<String?>(null);
  final capturedDevice = ''.obs;
  final remarksCtl = TextEditingController();

  // Enrolled templates extracted from biometricJsonUrl or candidate data
  final enrolledLeftTemplate = Rxn<Uint8List>();
  final enrolledRightTemplate = Rxn<Uint8List>();
  final isBiometricJsonLoaded = false.obs;
  final enrolledSidesIdentical =
      false.obs; // server par dono haath ka template same hai
  final matchState = 'waiting'
      .obs; // 'waiting' | 'matched' | 'mismatch' | 'no_template' | 'error'
  final matchScore = Rxn<int>();
  final matchMessage = ''.obs;

  // Kaunsa side button currently busy hai — sirf usi tap kiye par loading dikhega
  final scanningSide = Rxn<String>();
  final matchingSide = Rxn<String>();

  final isDetailLoading = false.obs;
  final detailErrorMessage = Rxn<String>();

  // Operator decision: 'verified' | 'rejected' | 'recheck'
  final verificationStatus = 'verified'.obs;
  final biometricMatch = false.obs;

  DeviceInfoController get _device => Get.find<DeviceInfoController>();

  /// Koi bhi side scan/match chal raha ho to dusre side ka button block karo.
  bool get anyScanInProgress =>
      scanningSide.value != null || matchingSide.value != null;

  @override
  void onInit() {
    super.onInit();
    // Prefill previously captured device scan images if available
    if (_device.leftFingerprintImage != null) {
      capturedLeftImage.value = _device.leftFingerprintImage;
      capturedLeftQuality.value =
          _device.leftBiometricData['Left_ImageQuality'] as int? ??
              _device.qualityScore;
    }
    if (_device.rightFingerprintImage != null) {
      capturedRightImage.value = _device.rightFingerprintImage;
      capturedRightQuality.value =
          _device.rightBiometricData['Right_ImageQuality'] as int? ??
              _device.qualityScore;
    }
  }

  void setCandidate(Candidate c) {
    candidate.value = c;
    capturedDevice.value = c.biometric.capturedDevice.isNotEmpty
        ? c.biometric.capturedDevice
        : 'ANDROID-DEVICE';
    detailErrorMessage.value = null;

    // Reset biometric match state and templates for the selected candidate
    enrolledLeftTemplate.value = null;
    enrolledRightTemplate.value = null;
    isBiometricJsonLoaded.value = false;
    enrolledSidesIdentical.value = false;
    matchState.value = 'waiting';
    matchScore.value = null;
    matchMessage.value = '';
    biometricMatch.value = false;
    capturedLeftQuality.value = null;
    capturedRightQuality.value = null;
    capturedLeftImage.value = null;
    capturedRightImage.value = null;

    // Check if templates are already in candidate.biometric
    _extractTemplatesFromBiometric(c.biometric);

    // Fetch full biometric JSON from biometricJsonUrl
    _fetchBiometricJson(c);
  }

  /// base64 me newline/data-URI ho to plain base64Decode fail ho jata hai.
  Uint8List? _decodeTemplate(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'^data:[a-zA-Z/+-]+;base64,'), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;
    try {
      final bytes = base64Decode(cleaned);
      // Khali/chhota blob template nahi ho sakta — slot bharne par candidate galati se reject hoga
      if (bytes.length < 48) {
        print(
            "⚠️ Biometric blob too short to be a template: ${bytes.length} bytes");
        return null;
      }
      return bytes;
    } catch (e) {
      print("Template base64 decode failed (${cleaned.length} chars): $e");
      return null;
    }
  }

  bool _sameBytes(Uint8List? a, Uint8List? b) {
    if (a == null || b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _checkEnrolledSanity() {
    final identical =
        _sameBytes(enrolledLeftTemplate.value, enrolledRightTemplate.value);
    enrolledSidesIdentical.value = identical;
    if (identical) {
      print(
          "⚠️ Enrolled LEFT and RIGHT templates are byte-identical — corrupted enrolment record");
    }
  }

  String _hexPrefix(Uint8List bytes, [int n = 6]) =>
      bytes.take(n).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  void _extractTemplatesFromBiometric(CandidateBiometric bio) {
    if (bio.leftTemplateBase64.isNotEmpty &&
        enrolledLeftTemplate.value == null) {
      enrolledLeftTemplate.value = _decodeTemplate(bio.leftTemplateBase64);
      if (enrolledLeftTemplate.value != null)
        isBiometricJsonLoaded.value = true;
    }
    if (bio.rightTemplateBase64.isNotEmpty &&
        enrolledRightTemplate.value == null) {
      enrolledRightTemplate.value = _decodeTemplate(bio.rightTemplateBase64);
      if (enrolledRightTemplate.value != null)
        isBiometricJsonLoaded.value = true;
    }
    _checkEnrolledSanity();
  }

  Future<void> _fetchBiometricJson(Candidate c) async {
    final bioUrl = c.biometric.biometricJsonUrl.trim();
    if (bioUrl.isEmpty) {
      print("ℹ️ No biometricJsonUrl provided for candidate ${c.name}");
      return;
    }

    try {
      String fullUrl = bioUrl;
      if (!fullUrl.startsWith('http://') && !fullUrl.startsWith('https://')) {
        fullUrl =
            '${VerifierApiService.baseUrl}/${fullUrl.replaceFirst(RegExp(r'^/+'), '')}';
      }
      print("🌐 Fetching biometric JSON from: $fullUrl");

      http.Response res;
      final uri = Uri.parse(fullUrl);
      // For S3 or external URLs, do NOT attach Bearer tokens because S3 rejects them
      final isExternal = !uri.host.contains('ubroapi.space');
      if (isExternal) {
        try {
          res = await http.get(uri).timeout(const Duration(seconds: 15));
        } catch (_) {
          res = await VerifierApiService.to
              .get(fullUrl)
              .timeout(const Duration(seconds: 15));
        }
      } else {
        res = await VerifierApiService.to
            .get(fullUrl)
            .timeout(const Duration(seconds: 15));
      }

      print("📥 Biometric JSON Status: ${res.statusCode}");
      if (res.statusCode == 200) {
        final dynamic decoded = jsonDecode(res.body);
        Map<String, dynamic> rootMap = {};
        if (decoded is Map<String, dynamic>) {
          rootMap = decoded;
        } else if (decoded is List &&
            decoded.isNotEmpty &&
            decoded.first is Map<String, dynamic>) {
          rootMap = decoded.first as Map<String, dynamic>;
        }

        // Deep search for template strings in the JSON map
        void searchMap(Map<String, dynamic> map, [String parentKey = '']) {
          map.forEach((k, v) {
            final keyLower = k.toLowerCase().replaceAll('_', '');
            final pLower = parentKey.toLowerCase().replaceAll('_', '');
            final combined = '${pLower}_$keyLower';

            if (v is String && v.trim().isNotEmpty) {
              final isTemplate =
                  keyLower.contains('template') || keyLower == 'isotemplate';
              final isLeft =
                  combined.contains('left') || keyLower.contains('left');
              final isRight =
                  combined.contains('right') || keyLower.contains('right');

              // Left template
              if (isTemplate && isLeft) {
                if (enrolledLeftTemplate.value == null) {
                  final bytes = _decodeTemplate(v);
                  if (bytes != null) {
                    enrolledLeftTemplate.value = bytes;
                    isBiometricJsonLoaded.value = true;
                    print(
                        "✅ Enrolled Left Template ${bytes.length} bytes [${_hexPrefix(bytes)}] from key '$k' (parent '$parentKey')");
                  }
                }
              }
              // Right template
              else if (isTemplate && isRight) {
                if (enrolledRightTemplate.value == null) {
                  final bytes = _decodeTemplate(v);
                  if (bytes != null) {
                    enrolledRightTemplate.value = bytes;
                    isBiometricJsonLoaded.value = true;
                    print(
                        "✅ Enrolled Right Template ${bytes.length} bytes [${_hexPrefix(bytes)}] from key '$k' (parent '$parentKey')");
                  }
                }
              }
              // Generic template
              else if (isTemplate &&
                  enrolledLeftTemplate.value == null &&
                  !isRight) {
                final bytes = _decodeTemplate(v);
                if (bytes != null) {
                  enrolledLeftTemplate.value = bytes;
                  isBiometricJsonLoaded.value = true;
                  print(
                      "✅ Enrolled Generic Template ${bytes.length} bytes [${_hexPrefix(bytes)}] from key '$k'");
                }
              }
            } else if (v is Map) {
              searchMap(Map<String, dynamic>.from(v), k);
            } else if (v is List) {
              // API aksar records ko array me wrap karta hai (e.g. biometricData: [ {...} ])
              for (final item in v) {
                if (item is Map) searchMap(Map<String, dynamic>.from(item), k);
              }
            }
          });
        }

        searchMap(rootMap);

        final fetchedBio = CandidateBiometric.fromJson(rootMap);
        _extractTemplatesFromBiometric(fetchedBio);
        _checkEnrolledSanity();

        final mergedBio = CandidateBiometric(
          biometricJsonUrl: c.biometric.biometricJsonUrl,
          leftThumb: c.biometric.leftThumb.isNotEmpty
              ? c.biometric.leftThumb
              : fetchedBio.leftThumb,
          rightThumb: c.biometric.rightThumb.isNotEmpty
              ? c.biometric.rightThumb
              : fetchedBio.rightThumb,
          leftTemplateBase64: c.biometric.leftTemplateBase64.isNotEmpty
              ? c.biometric.leftTemplateBase64
              : fetchedBio.leftTemplateBase64,
          rightTemplateBase64: c.biometric.rightTemplateBase64.isNotEmpty
              ? c.biometric.rightTemplateBase64
              : fetchedBio.rightTemplateBase64,
          livePhoto: c.biometric.livePhoto.isNotEmpty
              ? c.biometric.livePhoto
              : fetchedBio.livePhoto,
          biometricTime: c.biometric.biometricTime.isNotEmpty
              ? c.biometric.biometricTime
              : fetchedBio.biometricTime,
          attendanceTime: c.biometric.attendanceTime.isNotEmpty
              ? c.biometric.attendanceTime
              : fetchedBio.attendanceTime,
          capturedDevice: c.biometric.capturedDevice.isNotEmpty
              ? c.biometric.capturedDevice
              : fetchedBio.capturedDevice,
          status: c.biometric.status.isNotEmpty
              ? c.biometric.status
              : fetchedBio.status,
        );

        candidate.value = Candidate(
          id: c.id,
          examId: c.examId,
          examName: c.examName,
          examCode: c.examCode,
          rollNo: c.rollNo,
          studentId: c.studentId,
          applicationId: c.applicationId,
          name: c.name,
          fatherName: c.fatherName,
          motherName: c.motherName,
          mobile: c.mobile,
          email: c.email,
          photo: c.photo,
          centerId: c.centerId,
          centerCode: c.centerCode,
          centerName: c.centerName,
          centerDistrict: c.centerDistrict,
          status: c.status,
          attendanceReportId: c.attendanceReportId,
          lastVerifiedAt: c.lastVerifiedAt,
          biometricObj: mergedBio,
        );
      }
    } catch (e) {
      print("Biometric JSON fetch note: $e");
    }
  }

  Future<void> loadDetail(String candidateId) async {
    // Check if VerifierCandidatesController already has this candidate in memory
    if (candidate.value == null && Get.isRegistered<VerifierCandidatesController>()) {
      final candidatesList = Get.find<VerifierCandidatesController>().candidates;
      final local = candidatesList.firstWhereOrNull(
        (c) => c.id == candidateId || c.rollNo == candidateId,
      );
      if (local != null) {
        setCandidate(local);
      }
    }

    try {
      isDetailLoading.value = true;
      detailErrorMessage.value = null;
      final res =
          await VerifierApiService.to.get(VerifierApiService.urlCandidateDetail(candidateId));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          setCandidate(Candidate.fromJson(data));
        } else if (candidate.value == null) {
          detailErrorMessage.value = 'Unexpected candidate detail response';
        }
      } else {
        if (candidate.value == null) {
          detailErrorMessage.value =
              'Candidate detail failed (${res.statusCode})';
        }
      }
    } catch (e) {
      if (candidate.value == null) {
        detailErrorMessage.value =
            'Network issue: Candidate details could not be loaded.';
      }
    } finally {
      isDetailLoading.value = false;
    }
  }

  Future<void> scanFinger({required String side}) async {
    if (anyScanInProgress) return;
    scanningSide.value = side;
    matchState.value = 'waiting';
    matchMessage.value =
        "Scanner LED is active. Please place your $side finger firmly on the sensor glass...";
    final ok = await _device.scanFingerPrint(scanType: side, showToasts: false);
    scanningSide.value = null;
    if (ok) {
      final q = _device.qualityScore;
      if (side == 'left') {
        capturedLeftQuality.value = q;
        capturedLeftImage.value = _device.leftFingerprintImage;
      } else {
        capturedRightQuality.value = q;
        capturedRightImage.value = _device.rightFingerprintImage;
      }
      capturedDevice.value = _device.serialNumber ?? capturedDevice.value;

      // AUTOMATIC BIOMETRIC MATCHING WITH ENROLLED BIOMETRIC DATA
      final scannedTemplate = _device.fingerprintTemplate;
      final scannedIsoTemplate = _device.fingerprintIsoTemplate;
      if (scannedTemplate != null && scannedTemplate.isNotEmpty) {
        await matchCapturedFinger(scannedTemplate,
            side: side, isoTemplate: scannedIsoTemplate);
      }
    } else {
      if (matchState.value == 'waiting') {
        matchState.value = 'error';
        matchMessage.value = _device.lastScanError ??
            "Capture timed out or failed. Place finger firmly on sensor glass and try again.";
      }
    }
  }

  Future<void> matchCapturedFinger(Uint8List scannedTemplate,
      {required String side, Uint8List? isoTemplate}) async {
    matchingSide.value = side;
    try {
      // If templates not fetched yet, try immediate fetch
      if (enrolledLeftTemplate.value == null &&
          enrolledRightTemplate.value == null &&
          candidate.value != null) {
        await _fetchBiometricJson(candidate.value!);
      }

      // 1. Strict side-to-side match: left scan → enrolled LEFT only, right scan → enrolled RIGHT only
      final enrolledForSide = side == 'left'
          ? enrolledLeftTemplate.value
          : enrolledRightTemplate.value;
      final thumbName = side == 'left' ? 'LEFT Thumb' : 'RIGHT Thumb';

      if (enrolledForSide == null) {
        matchState.value = 'no_template';
        matchMessage.value =
            "Candidate ka $thumbName enrolled nahi hai — $side finger verify nahi ho sakta. Manual verification karein.";
        showError(
            "$thumbName enrolled template biometric JSON me nahi mila. Manual verification karein.");
        return;
      }

      final Uint8List primaryTemplate = enrolledForSide;
      final String matchDescription =
          "Enrolled ${side == 'left' ? 'Left' : 'Right'} Thumb";

      // Purane enrolment records me dono haath ka slot ek hi template hold karta tha
      final otherTemplate = side == 'left'
          ? enrolledRightTemplate.value
          : enrolledLeftTemplate.value;
      final sameBothHands = _sameBytes(otherTemplate, primaryTemplate);
      final dataCaution = sameBothHands
          ? ' (LEFT aur RIGHT dono ka stored template same hai — enrolment data kharab hai, candidate ko dobara enrol karein)'
          : '';

      // 2. Perform native matching via SecuGen FDx SDK (format-aware: SG400 / ISO 19794-2 / ANSI)
      final matchResult = await _device.matchFingerprint(
        scannedTemplate,
        primaryTemplate,
        liveIsoTemplate: isoTemplate,
      );
      bool isMatch = matchResult['matched'] == true;
      int score = matchResult['score'] as int? ?? 0;
      bool technicalError = matchResult['technicalError'] == true;

      matchScore.value = score;
      final formatNote = _templateFormatNote(matchResult);

      // 3. AUTO STATUS CHANGE BASED ON MATCH RESULT
      if (isMatch) {
        matchState.value = 'matched';
        biometricMatch.value = true;
        verificationStatus.value = 'verified'; // AUTO STATUS: VERIFIED
        matchMessage.value =
            "$thumbName MATCHED ($matchDescription, score: $score)";
      } else if (technicalError || sameBothHands) {
        // Format/SDK failure ya kharab enrolment data — genuine mismatch nahi, auto-reject nahi hoga
        matchState.value = 'error';
        biometricMatch.value = false;
        matchMessage.value = sameBothHands
            ? "Server par LEFT aur RIGHT dono ka template SAME hai — $side finger verify namumik. Candidate ko dobara enrol + sync karein.$formatNote"
            : "Enrolled template se matching complete nahi ho payi$formatNote$dataCaution. Status unchanged — manual verification karein.";
        showError(sameBothHands
            ? "Enrolment data kharab hai (dono haath ka template ek hi). Candidate re-enrol karein — REJECTED mat karein."
            : "Biometric Alert: Enrolled template match nahi ho paya$dataCaution. Candidate ko REJECTED mat karein.");
      } else {
        matchState.value = 'mismatch';
        biometricMatch.value = false;
        verificationStatus.value = 'rejected'; // AUTO STATUS: REJECTED
        matchMessage.value =
            "$thumbName MISMATCH (is finger ne $matchDescription se match nahi kiya)$formatNote$dataCaution";
        // showError(
        //   "Biometric Mismatch: $thumbName does NOT match $matchDescription. Status auto-set to REJECTED.",
        // );
      }
    } catch (e) {
      matchState.value = 'error';
      matchMessage.value = "Matching error: $e";
      print("Matching error: $e");
    } finally {
      matchingSide.value = null;
    }
  }

  String _templateFormatNote(Map<String, dynamic> r) {
    final fmt = (r['enrolledFormat']?.toString().isNotEmpty ?? false)
        ? r['enrolledFormat']
        : 'unknown';
    return ' [enrolled: $fmt/${r['enrolledSize']}B, live ISO: ${r['liveIsoSize']}B]';
  }

  Map<String, dynamic> buildPayload() {
    final c = candidate.value!;
    final isMatch = biometricMatch.value;
    final scores = [
      matchScore.value,
      capturedLeftQuality.value,
      capturedRightQuality.value
    ].whereType<int>();
    final avgScore =
        scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;

    return {
      'clientSyncId': _uuid.v4(),
      'candidateId': c.id,
      'verificationStatus': verificationStatus.value,
      'biometricMatch': isMatch,
      'biometricScore': avgScore,
      'biometricResult': isMatch ? 'MATCH' : 'NO_MATCH',
      'capturedDevice': capturedDevice.value.isEmpty
          ? 'ANDROID-DEVICE'
          : capturedDevice.value,
      'biometricJsonUrl': c.biometric.biometricJsonUrl,
      'leftThumb': c.biometric.leftThumb,
      'rightThumb': c.biometric.rightThumb,
      'livePhoto': c.biometric.livePhoto,
      'remarks': remarksCtl.text.trim(),
    };
  }

  Future<void> submitVerification() async {
    final c = candidate.value;
    if (c == null) {
      showError('Candidate not loaded');
      return;
    }
    final payload = buildPayload();
    final online = await VerifierSyncService.to.isOnline();

    try {
      showLoading(withDialog: false);
      if (online) {
        final res =
            await VerifierApiService.to.post(VerifierApiService.urlVerify(c.id), payload);
        hideLoading();
        if (res.statusCode == 200 || res.statusCode == 201) {
          _markLocalVerified(c);
          _autoBackWithFeedback(
            "Verified",
            "Candidate ${c.rollNo} submitted successfully",
          );
          return;
        }
        // Non-200 online: keep as queued so it is retried via bulk sync.
        await _queue(payload, c);
        _autoBackWithFeedback(
          "Saved Offline",
          "Server responded ${res.statusCode}. Queued for sync.",
        );
        return;
      }
      // Offline path
      hideLoading();
      await _queue(payload, c);
      _autoBackWithFeedback(
        "Saved Offline",
        "No internet. Verification queued for later sync.",
      );
    } catch (e) {
      hideLoading();
      await _queue(payload, c);
      _autoBackWithFeedback(
        "Saved Offline",
        "Network issue — queued for sync: $e",
        isError: true,
      );
    }
  }

  void _autoBackWithFeedback(String title, String message,
      {bool isError = false}) {
    // 1. First pop the VerifierCandidateDetailScreen
    if (Get.key.currentState?.canPop() ?? false) {
      Get.key.currentState?.pop();
    } else if (Get.context != null && Navigator.canPop(Get.context!)) {
      Navigator.pop(Get.context!);
    } else {
      Get.back();
    }

    // 2. Refresh dashboard summary in background if registered
    if (Get.isRegistered<VerifierDashboardController>()) {
      Get.find<VerifierDashboardController>().loadDashboard();
    }

    // 3. Show feedback snackbar on the returned screen
    Future.delayed(const Duration(milliseconds: 200), () {
      if (isError) {
        showError(message);
      } else {
        showSuccess(title, message);
      }
    });
  }

  Future<void> _queue(Map<String, dynamic> payload, Candidate c) async {
    final record = PendingVerification(
      clientSyncId: payload['clientSyncId'],
      candidateId: c.id,
      rollNo: c.rollNo,
      candidateName: c.name,
      verificationStatus: payload['verificationStatus'],
      payload: payload,
      createdAt: DateTime.now().toIso8601String(),
    );
    await VerifierSyncService.to.enqueue(record);
    _markLocalVerified(c);
  }

  void _markLocalVerified(Candidate c) {
    final updated = Candidate(
      id: c.id,
      examId: c.examId,
      examName: c.examName,
      examCode: c.examCode,
      rollNo: c.rollNo,
      studentId: c.studentId,
      applicationId: c.applicationId,
      name: c.name,
      fatherName: c.fatherName,
      motherName: c.motherName,
      mobile: c.mobile,
      email: c.email,
      photo: c.photo,
      centerId: c.centerId,
      centerCode: c.centerCode,
      centerName: c.centerName,
      centerDistrict: c.centerDistrict,
      status: verificationStatus.value,
      attendanceReportId: c.attendanceReportId,
      lastVerifiedAt: DateTime.now().toIso8601String(),
      biometricObj: c.biometric,
    );
    candidate.value = updated;
    if (Get.isRegistered<VerifierCandidatesController>()) {
      final ctl = Get.find<VerifierCandidatesController>();
      final idx = ctl.candidates.indexWhere((cand) => cand.id == c.id);
      if (idx != -1) {
        ctl.candidates[idx] = updated;
        ctl.candidates.refresh();
      }
    }
  }

  @override
  void onClose() {
    remarksCtl.dispose();
    capturedLeftImage.value = null;
    capturedRightImage.value = null;
    _device.clearBiometricData();
    super.onClose();
  }
}
 // showSuccess(
        //   "Biometric Match: VERIFIED",
        //   "$thumbName matched $matchDescription! Status auto-set to VERIFIED.",
        // );