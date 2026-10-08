import 'dart:convert';
import 'dart:typed_data';

import 'package:exam_shadule_new/controller/device_info_controller.dart';
import 'package:exam_shadule_new/verifier/controller/candidate_detail_controller.dart';
import 'package:exam_shadule_new/verifier/models/candidate.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('verify POST body matches agreed API schema', () {
    Get.put(DeviceInfoController());
    final c = VerifierCandidateDetailController();
    c.setCandidate(Candidate(
      id: 'cand-1',
      rollNo: '13010156',
      biometricObj: CandidateBiometric(
        leftThumb: 'ENROLLED_LEFT_B64',
        rightThumb: 'ENROLLED_RIGHT_B64',
        livePhoto: 'ENROLLED_LIVE_B64',
      ),
    ));

    c.verificationStatus.value = 'verified';
    c.biometricMatch.value = true;
    c.matchScore.value = 96;
    c.lastScannedTemplate.value = Uint8List.fromList([1, 2, 3]);

    final payload = c.buildPayload();
    print('PAYLOAD KEYS: ${payload.keys.toList()}');
    print(jsonEncode(payload));

    expect(payload.keys.toList(), [
      'clientSyncId',
      'verificationStatus',
      'biometricMatch',
      'biometricScore',
      'biometricResult',
      'leftThumb',
      'rightThumb',
      'livePhoto',
      'biometricData',
      'capturedDevice',
      'deviceId',
      'remarks',
    ]);
    expect(payload['clientSyncId'], startsWith('ANDROID-'));
    expect(payload['verificationStatus'], 'verified');
    expect(payload['biometricMatch'], true);
    expect(payload['biometricScore'], 96.0);
    expect(payload['biometricResult'], 'MATCH');
    // No fresh captures -> enrolled values are passed through
    expect(payload['leftThumb'], 'ENROLLED_LEFT_B64');
    expect(payload['rightThumb'], 'ENROLLED_RIGHT_B64');
    expect(payload['livePhoto'], 'ENROLLED_LIVE_B64');
    final bio = payload['biometricData'] as Map<String, dynamic>;
    expect(bio.keys.toList(), ['template', 'score', 'result']);
    expect(bio['template'], base64Encode(Uint8List.fromList([1, 2, 3])));
    expect(bio['score'], 96.0);
    expect(bio['result'], 'MATCH');
    expect(payload['capturedDevice'], 'ANDROID-DEVICE');
    expect(payload['deviceId'], '');
    expect(payload['remarks'], '');
  });
}
