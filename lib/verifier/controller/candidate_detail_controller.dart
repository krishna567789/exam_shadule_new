import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import '../models/candidate.dart';
import '../models/pending_verification.dart';
import '../services/api_service.dart';

import '../services/sync_service.dart';
import '../../controller/base_controller.dart';
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
  final livePhotoPath = Rx<String?>(null);
  final capturedDevice = ''.obs;
  final remarksCtl = TextEditingController();

  // Operator decision: 'verified' | 'rejected' | 'recheck'
  final verificationStatus = 'verified'.obs;
  final biometricMatch = true.obs;

  DeviceInfoController get _device => Get.find<DeviceInfoController>();

  Future<void> loadDetail(String candidateId) async {
    try {
      showLoading();
      final res = await VerifierApiService.to.get(VerifierApiService.urlCandidateDetail(candidateId));
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        final data = body is Map ? body['data'] : body;
        if (data is Map<String, dynamic>) {
          candidate.value = Candidate.fromJson(data);
          capturedDevice.value =
              candidate.value?.biometric.capturedDevice ?? 'ANDROID-DEVICE';
        } else {
          showError('Unexpected candidate detail response');
        }
      } else {
        showError('Candidate detail failed (${res.statusCode})');
      }
    } catch (e) {
      showError('Detail error: $e');
    } finally {
      hideLoading();
    }
  }

  Future<void> scanFinger({required String side}) async {
    final ok = await _device.scanFingerPrint(scanType: side);
    if (ok) {
      final q = _device.qualityScore;
      if (side == 'left') {
        capturedLeftQuality.value = q;
      } else {
        capturedRightQuality.value = q;
      }
      capturedDevice.value = _device.serialNumber ?? capturedDevice.value;
    }
  }

  Map<String, dynamic> buildPayload() {
    final c = candidate.value!;
    final isMatch = biometricMatch.value;
    final scores = [capturedLeftQuality.value, capturedRightQuality.value]
        .whereType<int>();
    final avgScore = scores.isEmpty
        ? 0.0
        : scores.reduce((a, b) => a + b) / scores.length;

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
      showLoading();
      if (online) {
        final res = await VerifierApiService.to
            .post(VerifierApiService.urlVerify(c.id), payload);
        if (res.statusCode == 200 || res.statusCode == 201) {
          hideLoading();
          _markLocalVerified(c);
          showSuccess("Verified",
              "Candidate ${c.rollNo} submitted successfully");
          Get.back();
          return;
        }
        // Non-200 online: keep as queued so it is retried via bulk sync.
        hideLoading();
        await _queue(payload, c);
        showSuccess("Saved Offline",
            "Server responded ${res.statusCode}. Queued for sync.");
        Get.back();
        return;
      }
      // Offline path
      hideLoading();
      await _queue(payload, c);
      showSuccess("Saved Offline",
          "No internet. Verification queued for later sync.");
      Get.back();
    } catch (e) {
      hideLoading();
      await _queue(payload, c);
      showError("Network issue — queued for sync: $e");
      Get.back();
    }
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
    candidate.value = Candidate(
      id: c.id, examId: c.examId, examName: c.examName, examCode: c.examCode,
      rollNo: c.rollNo, studentId: c.studentId, applicationId: c.applicationId,
      name: c.name, fatherName: c.fatherName, motherName: c.motherName,
      mobile: c.mobile, email: c.email, photo: c.photo, centerId: c.centerId,
      centerCode: c.centerCode, centerName: c.centerName,
      centerDistrict: c.centerDistrict,
      status: verificationStatus.value,
      attendanceReportId: c.attendanceReportId,
      lastVerifiedAt: DateTime.now().toIso8601String(),
      biometricObj: c.biometric,
    );
  }

  @override
  void onClose() {
    remarksCtl.dispose();
    _device.clearBiometricData();
    super.onClose();
  }
}
