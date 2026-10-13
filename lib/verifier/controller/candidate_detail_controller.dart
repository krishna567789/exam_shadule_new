import 'dart:convert';
import 'dart:io';
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
  final capturedLeftImageUrl = Rxn<String>();
  final capturedRightImageUrl = Rxn<String>();
  final lastScannedTemplate = Rxn<Uint8List>();
  final livePhotoPath = Rx<String?>(null);
  final capturedDevice = ''.obs;
  final remarksCtl = TextEditingController();

  // Enrolled templates extracted from biometricJsonUrl or candidate data
  final enrolledLeftTemplate = Rxn<Uint8List>();
  final enrolledRightTemplate = Rxn<Uint8List>();
  final isBiometricJsonLoaded = false.obs;
  final enrolledSidesIdentical =
      false.obs; // both left and right enrolled templates are identical on the server
  final matchState = 'waiting'
      .obs; // 'waiting' | 'matched' | 'mismatch' | 'no_template' | 'error'
  final matchScore = Rxn<int>();
  final matchMessage = ''.obs;

  // Which side button is currently busy — spinner shows only on tapped side
  final scanningSide = Rxn<String>();
  final matchingSide = Rxn<String>();

  final isDetailLoading = false.obs;
  final detailErrorMessage = Rxn<String>();

  // Operator decision: 'pending' | 'verified' | 'rejected' | 'recheck'
  final verificationStatus = 'pending'.obs;
  final biometricMatch = false.obs;

  /// Switch: false = Biometric Mode (candidate finger must match), true = Manual Verification (bypasses match)
  final isManualVerification = false.obs;

  DeviceInfoController get _device => Get.find<DeviceInfoController>();

  /// Block other scan/match button while an operation is in progress.
  bool get anyScanInProgress =>
      scanningSide.value != null || matchingSide.value != null;

  @override
  void onInit() {
    super.onInit();
    // Do NOT prefill previously captured device scan images.
    // Captured images on device belong only to verified candidates or live scans.
    _device.clearBiometricData();
  }

  void setCandidate(Candidate c) {
    candidate.value = c;
    capturedDevice.value = c.biometric.capturedDevice.isNotEmpty
        ? c.biometric.capturedDevice
        : 'ANDROID-DEVICE';
    detailErrorMessage.value = null;

    final initialStatus = c.status.toLowerCase().trim();
    verificationStatus.value =
        initialStatus.isNotEmpty ? initialStatus : 'pending';

    // Reset biometric match state and templates for the selected candidate
    enrolledLeftTemplate.value = null;
    enrolledRightTemplate.value = null;
    isBiometricJsonLoaded.value = false;
    enrolledSidesIdentical.value = false;
    isManualVerification.value = false;
    capturedLeftQuality.value = null;
    capturedRightQuality.value = null;
    capturedLeftImage.value = null;
    capturedRightImage.value = null;
    capturedLeftImageUrl.value = null;
    capturedRightImageUrl.value = null;
    lastScannedTemplate.value = null;
    _device.clearBiometricData();

    final isVerified = initialStatus == 'verified';

    if (isVerified) {
      matchState.value = 'matched';
      matchScore.value = null;
      matchMessage.value = 'Candidate is already verified.';
      biometricMatch.value = true;
      // Populate captured biometrics ONLY for verified candidate
      _populateCapturedBiometricsFromCandidate(c);
    } else if (initialStatus == 'rejected') {
      matchState.value = 'mismatch';
      matchScore.value = null;
      matchMessage.value = 'Candidate was previously rejected.';
      biometricMatch.value = false;
    } else {
      matchState.value = 'waiting';
      matchScore.value = null;
      matchMessage.value = '';
      biometricMatch.value = false;
    }

    // Check if enrolled templates are already in candidate.biometric
    _extractTemplatesFromBiometric(c.biometric);

    // Fetch full biometric JSON from biometricJsonUrl
    _fetchBiometricJson(c);
  }

  void toggleManualVerification(bool val) {
    isManualVerification.value = val;
    if (val) {
      verificationStatus.value = 'verified';
      if (matchState.value != 'matched') {
        matchState.value = lastScannedTemplate.value != null
            ? 'manual_captured'
            : 'manual_mode';
        matchMessage.value =
            'Manual verification mode enabled. Biometric matching is bypassed.';
      }
    } else {
      if (matchState.value == 'manual_mode' ||
          matchState.value == 'manual_captured') {
        if (biometricMatch.value) {
          matchState.value = 'matched';
          verificationStatus.value = 'verified';
        } else {
          matchState.value =
              lastScannedTemplate.value != null ? 'mismatch' : 'waiting';
          final initialStatus =
              candidate.value?.status.toLowerCase().trim() ?? 'pending';
          verificationStatus.value = lastScannedTemplate.value != null
              ? 'rejected'
              : (initialStatus.isNotEmpty ? initialStatus : 'pending');
        }
      }
    }
  }

  /// If base64 contains newlines or data-URI prefix, plain base64Decode fails.
  Uint8List? _decodeTemplate(String raw) {
    final cleaned = raw
        .trim()
        .replaceAll(RegExp(r'^data:[a-zA-Z/+-]+;base64,'), '')
        .replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;
    try {
      final bytes = base64Decode(cleaned);
      // Empty or too small blob cannot be a valid template — filling it would cause false rejection
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

  /// Clean and decode base64 fingerprint image (PNG/BMP/WSQ) to Uint8List.
  Uint8List? _decodeImageBytes(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('/') ||
        trimmed.startsWith('assets/')) {
      return null;
    }
    String cleaned = trimmed;
    final commaIdx = cleaned.indexOf(',');
    if (cleaned.startsWith('data:') && commaIdx != -1) {
      cleaned = cleaned.substring(commaIdx + 1);
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    if (cleaned.isEmpty) return null;

    final padRemainder = cleaned.length % 4;
    if (padRemainder > 0) {
      cleaned += '=' * (4 - padRemainder);
    }

    try {
      final bytes = base64Decode(cleaned);
      if (bytes.length > 50) return bytes;
    } catch (e) {
      print("Fingerprint base64 decode note (${cleaned.length} chars): $e");
    }
    return null;
  }

  void _populateCapturedBiometricsFromCandidate(Candidate c) {
    final isVerified = c.status.toLowerCase().trim() == 'verified';
    // Candidates who are NOT verified must NOT have captured finger images pre-populated
    // "jo candidate verified hai unka hi capture on device me finger ka image ayega"
    if (!isVerified) {
      capturedLeftImage.value = null;
      capturedLeftImageUrl.value = null;
      capturedLeftQuality.value = null;
      capturedRightImage.value = null;
      capturedRightImageUrl.value = null;
      capturedRightQuality.value = null;
      return;
    }

    // 1. Left Thumb for verified candidate
    final verBio = c.verificationBiometric;
    final leftThumb = (verBio != null && verBio.leftThumb.isNotEmpty)
        ? verBio.leftThumb
        : c.biometric.leftThumb;
    final leftQuality = verBio?.leftQuality ?? c.biometric.leftQuality;

    if (leftThumb.isNotEmpty) {
      capturedLeftImageUrl.value = leftThumb;
      final bytes = _decodeImageBytes(leftThumb);
      if (bytes != null) capturedLeftImage.value = bytes;
      if (leftQuality != null) {
        capturedLeftQuality.value = leftQuality;
      }
    }

    // 2. Right Thumb for verified candidate
    final rightThumb = (verBio != null && verBio.rightThumb.isNotEmpty)
        ? verBio.rightThumb
        : c.biometric.rightThumb;
    final rightQuality = verBio?.rightQuality ?? c.biometric.rightQuality;

    if (rightThumb.isNotEmpty) {
      capturedRightImageUrl.value = rightThumb;
      final bytes = _decodeImageBytes(rightThumb);
      if (bytes != null) capturedRightImage.value = bytes;
      if (rightQuality != null) {
        capturedRightQuality.value = rightQuality;
      }
    }
  }

  void _extractBiometricDataFromMap(Map<String, dynamic> rootMap) {
    String? leftTplStr;
    String? rightTplStr;
    String? leftImgStr;
    String? rightImgStr;
    int? leftQuality;
    int? rightQuality;
    int? bioScore;

    String? findString(Map m, List<String> keys) {
      for (final k in keys) {
        if (m[k] != null && m[k].toString().trim().isNotEmpty) {
          return m[k].toString().trim();
        }
      }
      return null;
    }

    int? findInt(Map m, List<String> keys) {
      for (final k in keys) {
        if (m[k] != null) {
          final val = int.tryParse(m[k].toString().trim());
          if (val != null) return val;
        }
      }
      return null;
    }

    // Deep recursive search in map
    void searchMap(Map<String, dynamic> map, [String parentKey = '']) {
      final pLower = parentKey.toLowerCase().replaceAll('_', '');

      map.forEach((k, v) {
        final keyLower = k.toLowerCase().replaceAll('_', '');
        final combined = '${pLower}_$keyLower';
        final isLeft = combined.contains('left') || keyLower.contains('left');
        final isRight =
            combined.contains('right') || keyLower.contains('right');

        if (v is String && v.trim().isNotEmpty) {
          final isTemplate =
              keyLower.contains('template') || keyLower == 'isotemplate';
          final isImage = keyLower.contains('bmp') ||
              keyLower.contains('wsq') ||
              keyLower.contains('thumb') ||
              keyLower.contains('finger') ||
              keyLower.contains('image');

          // Left template
          if (isTemplate && isLeft) {
            leftTplStr ??= v;
          } else if (isTemplate && isRight) {
            rightTplStr ??= v;
          } else if (isTemplate && !isRight) {
            leftTplStr ??= v;
          }

          // Left image
          if (isImage && isLeft && v.length > 50) {
            if (keyLower.contains('bmp') || leftImgStr == null) {
              leftImgStr = v;
            }
          }
          // Right image
          else if (isImage && isRight && v.length > 50) {
            if (keyLower.contains('bmp') || rightImgStr == null) {
              rightImgStr = v;
            }
          }
        } else if (v is num) {
          final isQuality =
              keyLower.contains('quality') || keyLower.contains('score');
          if (isQuality && isLeft) {
            leftQuality ??= v.toInt();
          } else if (isQuality && isRight) {
            rightQuality ??= v.toInt();
          } else if (isQuality && !isRight && leftQuality == null) {
            leftQuality ??= v.toInt();
          }
          if (keyLower.contains('biometricscore') || keyLower == 'score') {
            bioScore ??= v.toInt();
          }
        } else if (v is Map) {
          searchMap(Map<String, dynamic>.from(v), k);
        } else if (v is List) {
          for (final item in v) {
            if (item is Map) searchMap(Map<String, dynamic>.from(item), k);
          }
        }
      });
    }

    searchMap(rootMap);

    // Direct root / nested key checks
    leftTplStr ??= findString(rootMap, [
      'Left_TemplateBase64',
      'Left_Template',
      'left_template',
      'leftTemplate',
      'leftTemplateBase64',
      'TemplateBase64'
    ]);
    rightTplStr ??= findString(rootMap, [
      'Right_TemplateBase64',
      'Right_Template',
      'right_template',
      'rightTemplate',
      'rightTemplateBase64'
    ]);

    leftImgStr ??= findString(rootMap, [
      'Left_BMPBase64',
      'Left_WSQImage',
      'leftThumb',
      'left_thumb',
      'leftThumbUrl',
      'leftThumbImage',
      'leftThumbBase64'
    ]);
    rightImgStr ??= findString(rootMap, [
      'Right_BMPBase64',
      'Right_WSQImage',
      'rightThumb',
      'right_thumb',
      'rightThumbUrl',
      'rightThumbImage',
      'rightThumbBase64'
    ]);

    leftQuality ??= findInt(rootMap, [
      'Left_ImageQuality',
      'left_image_quality',
      'Left_Quality',
      'leftQuality',
      'ImageQuality'
    ]);
    rightQuality ??= findInt(rootMap, [
      'Right_ImageQuality',
      'right_image_quality',
      'Right_Quality',
      'rightQuality'
    ]);

    bioScore ??=
        findInt(rootMap, ['biometricScore', 'score', 'biometric_score']);

    // Apply Enrolled Templates
    if (leftTplStr != null && enrolledLeftTemplate.value == null) {
      final bytes = _decodeTemplate(leftTplStr!);
      if (bytes != null) {
        enrolledLeftTemplate.value = bytes;
        isBiometricJsonLoaded.value = true;
        print("✅ Enrolled Left Template ${bytes.length} bytes");
      }
    }
    if (rightTplStr != null && enrolledRightTemplate.value == null) {
      final bytes = _decodeTemplate(rightTplStr!);
      if (bytes != null) {
        enrolledRightTemplate.value = bytes;
        isBiometricJsonLoaded.value = true;
        print("✅ Enrolled Right Template ${bytes.length} bytes");
      }
    }

    // Apply Captured Images & Quality (ONLY for verified candidates and if no live scan done in this session)
    final isVerified = candidate.value?.status.toLowerCase().trim() == 'verified' ||
        verificationStatus.value == 'verified';

    if (isVerified && lastScannedTemplate.value == null) {
      if (leftImgStr != null && leftImgStr!.isNotEmpty) {
        capturedLeftImageUrl.value = leftImgStr;
        final bytes = _decodeImageBytes(leftImgStr!);
        if (bytes != null) {
          capturedLeftImage.value = bytes;
          print("✅ Captured Left Finger Image decoded (${bytes.length} bytes)");
        }
      }
      if (leftQuality != null) {
        capturedLeftQuality.value = leftQuality;
      }

      if (rightImgStr != null && rightImgStr!.isNotEmpty) {
        capturedRightImageUrl.value = rightImgStr;
        final bytes = _decodeImageBytes(rightImgStr!);
        if (bytes != null) {
          capturedRightImage.value = bytes;
          print(
              "✅ Captured Right Finger Image decoded (${bytes.length} bytes)");
        }
      }
      if (rightQuality != null) {
        capturedRightQuality.value = rightQuality;
      }

      if (bioScore != null && matchScore.value == null) {
        matchScore.value = bioScore;
      }
    }

    _checkEnrolledSanity();
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
          res = await http.get(uri).timeout(const Duration(seconds: 40));
        } catch (_) {
          res = await VerifierApiService.to
              .get(fullUrl)
              .timeout(const Duration(seconds: 40));
        }
      } else {
        res = await VerifierApiService.to
            .get(fullUrl)
            .timeout(const Duration(seconds: 40));
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

        // Deep search and extraction for templates, captured images, and qualities
        _extractBiometricDataFromMap(rootMap);

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
          leftQuality: fetchedBio.leftQuality ?? c.biometric.leftQuality,
          rightQuality: fetchedBio.rightQuality ?? c.biometric.rightQuality,
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
          verificationBiometric: c.verificationBiometric,
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
          final loadedCand = Candidate.fromJson(data);
          if (lastScannedTemplate.value == null && !biometricMatch.value) {
            setCandidate(loadedCand);
          } else {
            candidate.value = loadedCand;
          }
          _extractBiometricDataFromMap(data);
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
        capturedLeftImageUrl.value = null;
      } else {
        capturedRightQuality.value = q;
        capturedRightImage.value = _device.rightFingerprintImage;
        capturedRightImageUrl.value = null;
      }
      capturedDevice.value = _device.serialNumber ?? capturedDevice.value;

      // AUTOMATIC BIOMETRIC MATCHING WITH ENROLLED BIOMETRIC DATA
      final scannedTemplate = _device.fingerprintTemplate;
      final scannedIsoTemplate = _device.fingerprintIsoTemplate;
      if (scannedTemplate != null && scannedTemplate.isNotEmpty) {
        lastScannedTemplate.value = scannedTemplate;
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
        if (isManualVerification.value) {
          matchState.value = 'manual_captured';
          matchMessage.value =
              "$thumbName captured (Manual Mode: enrolled template not found)";
          verificationStatus.value = 'verified';
          return;
        }
        matchState.value = 'no_template';
        matchMessage.value =
            "Candidate's $thumbName is not enrolled — $side finger cannot be verified. Please perform manual verification.";
        showError(
            "$thumbName enrolled template not found in biometric JSON. Please perform manual verification.");
        return;
      }

      final Uint8List primaryTemplate = enrolledForSide;
      final String matchDescription =
          "Enrolled ${side == 'left' ? 'Left' : 'Right'} Thumb";

      // In older enrolment records, both hands might have stored the same template
      final otherTemplate = side == 'left'
          ? enrolledRightTemplate.value
          : enrolledLeftTemplate.value;
      final sameBothHands = _sameBytes(otherTemplate, primaryTemplate);
      final dataCaution = sameBothHands
          ? ' (Stored templates for LEFT and RIGHT are identical — invalid enrolment data, please re-enrol candidate)'
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
      } else if (isManualVerification.value) {
        // Switch is ON: Manual Mode — Candidate's finger captured, match bypassed
        matchState.value = 'manual_captured';
        biometricMatch.value = false;
        verificationStatus.value = 'verified';
        matchMessage.value =
            "$thumbName captured (Manual Mode: Score $score%, match not required)";
      } else if (technicalError || sameBothHands) {
        // Format/SDK failure or invalid enrolment data — not a genuine mismatch, avoid auto-rejecting
        matchState.value = 'error';
        biometricMatch.value = false;
        matchMessage.value = sameBothHands
            ? "Stored templates for LEFT and RIGHT are identical on the server — $side finger verification not possible. Please re-enrol and sync candidate.$formatNote"
            : "Could not complete matching with enrolled template$formatNote$dataCaution. Status unchanged — please perform manual verification.";
        showError(sameBothHands
            ? "Enrolment data is invalid (both hands share the same template). Please re-enrol candidate — do not mark as REJECTED."
            : "Biometric Alert: Could not match enrolled template$dataCaution. Do not mark candidate as REJECTED.");
      } else {
        matchState.value = 'mismatch';
        biometricMatch.value = false;
        verificationStatus.value = 'rejected'; // AUTO STATUS: REJECTED
        matchMessage.value =
            "$thumbName MISMATCH (finger did not match $matchDescription)$formatNote$dataCaution";
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
    final isManual = isManualVerification.value;
    final result = isMatch ? 'MATCH' : (isManual ? 'MANUAL' : 'NO_MATCH');

    double score;
    if (matchScore.value != null) {
      score = matchScore.value!.toDouble();
    } else {
      final q = [
        capturedLeftQuality.value,
        capturedRightQuality.value
      ].whereType<int>();
      score = q.isEmpty ? 0 : q.reduce((a, b) => a + b) / q.length;
    }

    String b64(Uint8List? bytes) =>
        bytes == null || bytes.isEmpty ? '' : base64Encode(bytes);

    String freshOrStored(Uint8List? captured, String stored) {
      final fresh = b64(captured);
      return fresh.isNotEmpty ? fresh : stored.trim();
    }

    String livePhoto = '';
    final path = livePhotoPath.value;
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (f.existsSync()) livePhoto = base64Encode(f.readAsBytesSync());
      } catch (_) {}
    }
    if (livePhoto.isEmpty) livePhoto = c.biometric.livePhoto.trim();

    String finalRemarks = remarksCtl.text.trim();
    if (isManual && finalRemarks.isEmpty) {
      finalRemarks = 'Manual Verification';
    }

    return {
      'clientSyncId': 'ANDROID-${_uuid.v4()}',
      'verificationStatus': verificationStatus.value,
      'biometricMatch': isMatch || isManual,
      'isManual': isManual,
      'manualVerification': isManual,
      'biometricScore': score,
      'biometricResult': result,
      'leftThumb': freshOrStored(capturedLeftImage.value, c.biometric.leftThumb),
      'rightThumb':
          freshOrStored(capturedRightImage.value, c.biometric.rightThumb),
      'livePhoto': livePhoto,
      'biometricData': {
        'template': b64(lastScannedTemplate.value),
        'score': score,
        'result': result,
        'isManual': isManual,
      },
      'capturedDevice': 'ANDROID-DEVICE',
      'deviceId': _device.serialNumber ?? '',
      'remarks': finalRemarks,
    };
  }

  Future<void> submitVerification() async {
    final c = candidate.value;
    if (c == null) {
      showError('Candidate not loaded');
      return;
    }

    // Validation when candidate is still in pending status:
    if (verificationStatus.value == 'pending') {
      showError(
        "Please complete verification (scan candidate finger or select status) before submitting.",
      );
      return;
    }

    // Validation when switch is OFF (Biometric Mode):
    // Verifier candidate ka finger lega aur match hona zaroori hai!
    if (!isManualVerification.value && verificationStatus.value == 'verified') {
      if (!biometricMatch.value) {
        showError(
          "Biometric match required to verify candidate. Please scan candidate's finger on the device, or turn ON Manual Verification.",
        );
        return;
      }
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
      // Candidate ID is required for identification during bulk sync
      payload: {...payload, 'candidateId': c.id},
      createdAt: DateTime.now().toIso8601String(),
    );
    await VerifierSyncService.to.enqueue(record);
    _markLocalVerified(c);
  }

  void _markLocalVerified(Candidate c) {
    String b64(Uint8List? bytes) =>
        bytes == null || bytes.isEmpty ? '' : base64Encode(bytes);
    String freshOrStored(Uint8List? captured, String stored) {
      final fresh = b64(captured);
      return fresh.isNotEmpty ? fresh : stored.trim();
    }

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
      verificationBiometric: CandidateBiometric(
        leftThumb: freshOrStored(capturedLeftImage.value, c.biometric.leftThumb),
        rightThumb:
            freshOrStored(capturedRightImage.value, c.biometric.rightThumb),
        leftQuality: capturedLeftQuality.value,
        rightQuality: capturedRightQuality.value,
        status: verificationStatus.value,
      ),
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
    capturedLeftImageUrl.value = null;
    capturedRightImageUrl.value = null;
    _device.clearBiometricData();
    super.onClose();
  }
}
 // showSuccess(
        //   "Biometric Match: VERIFIED",
        //   "$thumbName matched $matchDescription! Status auto-set to VERIFIED.",
        // );