import 'dart:convert';

/// Enrolled biometric reference for a candidate (URLs or base64 returned by backend).
class CandidateBiometric {
  final String biometricJsonUrl;
  final String leftThumb;
  final String rightThumb;
  final String leftTemplateBase64;
  final String rightTemplateBase64;
  final String livePhoto;
  final String biometricTime;
  final String attendanceTime;
  final String capturedDevice;
  final String status;
  final int? leftQuality;
  final int? rightQuality;

  CandidateBiometric({
    this.biometricJsonUrl = '',
    this.leftThumb = '',
    this.rightThumb = '',
    this.leftTemplateBase64 = '',
    this.rightTemplateBase64 = '',
    this.livePhoto = '',
    this.biometricTime = '',
    this.attendanceTime = '',
    this.capturedDevice = '',
    this.status = '',
    this.leftQuality,
    this.rightQuality,
  });

  factory CandidateBiometric.fromJson(Map<String, dynamic> rawJson) {
    Map<String, dynamic> json = Map<String, dynamic>.from(rawJson);

    // Enrolment app sync payload sends templates in nested 'biometricData' map
    // (Left_TemplateBase64 / Right_TemplateBase64) — merge them with root keys.
    if (rawJson['biometricData'] is Map) {
      json = {...Map<String, dynamic>.from(rawJson['biometricData'] as Map), ...json};
    }

    String? leftTpl;
    String? rightTpl;
    String? leftImg;
    String? rightImg;
    int? leftQuality;
    int? rightQuality;

    String findVal(Map m, List<String> keys) {
      for (final k in keys) {
        if (m[k] != null && m[k].toString().trim().isNotEmpty) {
          return m[k].toString().trim();
        }
      }
      return '';
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

    // 1. Check nested left sub-maps
    for (final lk in ['leftBiometricData', 'left_biometric_data', 'left', 'leftThumbData', 'leftBiometric']) {
      if (rawJson[lk] is Map) {
        final lm = rawJson[lk] as Map;
        final t = findVal(lm, ['TemplateBase64', 'templateBase64', 'Template', 'template', 'isoTemplate', 'IsoTemplate', 'Left_TemplateBase64']);
        if (t.isNotEmpty && leftTpl == null) leftTpl = t;
        final img = findVal(lm, ['BMPBase64', 'WSQImage', 'image', 'Image', 'thumbImage', 'thumb', 'Left_WSQImage', 'Left_BMPBase64']);
        if (img.isNotEmpty && leftImg == null) leftImg = img;
        final q = findInt(lm, ['ImageQuality', 'quality', 'Left_ImageQuality', 'leftQuality', 'left_image_quality']);
        if (q != null && leftQuality == null) leftQuality = q;
      }
    }

    // 2. Check nested right sub-maps
    for (final rk in ['rightBiometricData', 'right_biometric_data', 'right', 'rightThumbData', 'rightBiometric']) {
      if (rawJson[rk] is Map) {
        final rm = rawJson[rk] as Map;
        final t = findVal(rm, ['TemplateBase64', 'templateBase64', 'Template', 'template', 'isoTemplate', 'IsoTemplate', 'Right_TemplateBase64']);
        if (t.isNotEmpty && rightTpl == null) rightTpl = t;
        final img = findVal(rm, ['BMPBase64', 'WSQImage', 'image', 'Image', 'thumbImage', 'thumb', 'Right_WSQImage', 'Right_BMPBase64']);
        if (img.isNotEmpty && rightImg == null) rightImg = img;
        final q = findInt(rm, ['ImageQuality', 'quality', 'Right_ImageQuality', 'rightQuality', 'right_image_quality']);
        if (q != null && rightQuality == null) rightQuality = q;
      }
    }

    // 3. Check root-level keys
    final rootLeftTpl = findVal(json, [
      'Left_TemplateBase64', 'Left_Template', 'left_template', 'leftTemplate', 'leftTemplateBase64',
    ]);
    if (rootLeftTpl.isNotEmpty) leftTpl ??= rootLeftTpl;

    final rootRightTpl = findVal(json, [
      'Right_TemplateBase64', 'Right_Template', 'right_template', 'rightTemplate', 'rightTemplateBase64',
    ]);
    if (rootRightTpl.isNotEmpty) rightTpl ??= rootRightTpl;

    final rootLeftImg = findVal(json, [
      'Left_BMPBase64', 'Left_WSQImage', 'leftThumb', 'left_thumb', 'leftThumbUrl', 'leftThumbImage', 'leftFinger', 'left_finger', 'leftThumbBase64', 'left',
    ]);
    if (rootLeftImg.isNotEmpty) leftImg ??= rootLeftImg;

    final rootRightImg = findVal(json, [
      'Right_BMPBase64', 'Right_WSQImage', 'rightThumb', 'right_thumb', 'rightThumbUrl', 'rightThumbImage', 'rightFinger', 'right_finger', 'rightThumbBase64', 'right',
    ]);
    if (rootRightImg.isNotEmpty) rightImg ??= rootRightImg;

    final rootLeftQ = findInt(json, [
      'Left_ImageQuality', 'left_image_quality', 'Left_Quality', 'leftQuality', 'ImageQuality', 'qualityScore', 'quality',
    ]);
    if (rootLeftQ != null) leftQuality ??= rootLeftQ;

    final rootRightQ = findInt(json, [
      'Right_ImageQuality', 'right_image_quality', 'Right_Quality', 'rightQuality',
    ]);
    if (rootRightQ != null) rightQuality ??= rootRightQ;

    // 4. Fallback to generic template if neither is set
    if (leftTpl == null && rightTpl == null) {
      final genTpl = findVal(json, ['TemplateBase64', 'templateBase64', 'Template', 'template', 'isoTemplate', 'IsoTemplate']);
      if (genTpl.isNotEmpty) leftTpl = genTpl;
    }

    return CandidateBiometric(
      biometricJsonUrl: findVal(json, ['biometricJsonUrl', 'biometric_json_url', 'jsonUrl', 'biometricUrl']),
      leftThumb: leftImg ?? '',
      rightThumb: rightImg ?? '',
      leftTemplateBase64: leftTpl ?? '',
      rightTemplateBase64: rightTpl ?? '',
      livePhoto: findVal(json, [
        'livePhoto', 'live_photo', 'livePhotoUrl', 'livePhotoImage',
        'live_image', 'candidateLivePhoto', 'photo',
      ]),
      biometricTime: findVal(json, ['biometricTime', 'biometric_time', 'time']),
      attendanceTime: findVal(json, ['attendanceTime', 'attendance_time']),
      capturedDevice: findVal(json, ['capturedDevice', 'captured_device', 'device', 'deviceName', 'SerialNumber']),
      status: findVal(json, ['status', 'biometricStatus', 'result']),
      leftQuality: leftQuality,
      rightQuality: rightQuality,
    );
  }

  Map<String, dynamic> toJson() => {
        'biometricJsonUrl': biometricJsonUrl,
        'leftThumb': leftThumb,
        'rightThumb': rightThumb,
        'leftTemplateBase64': leftTemplateBase64,
        'rightTemplateBase64': rightTemplateBase64,
        'livePhoto': livePhoto,
        'biometricTime': biometricTime,
        'attendanceTime': attendanceTime,
        'capturedDevice': capturedDevice,
        'status': status,
        if (leftQuality != null) 'leftQuality': leftQuality,
        if (rightQuality != null) 'rightQuality': rightQuality,
      };
}

class Candidate {
  final String id;
  final String examId;
  final String examName;
  final String examCode;
  final String rollNo;
  final String studentId;
  final String applicationId;
  final String name;
  final String fatherName;
  final String motherName;
  final String mobile;
  final String email;
  final String photo;
  final String centerId;
  final String centerCode;
  final String centerName;
  final String centerDistrict;
  final String status;
  final String attendanceReportId;
  final String lastVerifiedAt;
  final CandidateBiometric biometric;
  final CandidateBiometric? verificationBiometric;

  Candidate({
    this.id = '',
    this.examId = '',
    this.examName = '',
    this.examCode = '',
    this.rollNo = '',
    this.studentId = '',
    this.applicationId = '',
    this.name = '',
    this.fatherName = '',
    this.motherName = '',
    this.mobile = '',
    this.email = '',
    this.photo = '',
    this.centerId = '',
    this.centerCode = '',
    this.centerName = '',
    this.centerDistrict = '',
    this.status = 'pending',
    this.attendanceReportId = '',
    this.lastVerifiedAt = '',
    CandidateBiometric? biometricObj,
    this.verificationBiometric,
  }) : biometric = biometricObj ?? CandidateBiometric();

  factory Candidate.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> bioMap = {};
    if (json['biometric'] is Map<String, dynamic>) {
      bioMap = Map<String, dynamic>.from(json['biometric'] as Map<String, dynamic>);
    } else if (json['biometric'] is String) {
      try {
        final d = jsonDecode(json['biometric']);
        if (d is Map<String, dynamic>) bioMap = d;
      } catch (_) {}
    } else if (json['biometrics'] is Map<String, dynamic>) {
      bioMap = Map<String, dynamic>.from(json['biometrics'] as Map<String, dynamic>);
    } else if (json['biometricData'] is Map<String, dynamic>) {
      bioMap = Map<String, dynamic>.from(json['biometricData'] as Map<String, dynamic>);
    }

    if (json['leftBiometricData'] is Map) {
      bioMap['leftBiometricData'] = json['leftBiometricData'];
    }
    if (json['rightBiometricData'] is Map) {
      bioMap['rightBiometricData'] = json['rightBiometricData'];
    }

    // Parse dedicated verification biometric if present
    CandidateBiometric? verBio;
    if (json['verification'] is Map) {
      verBio = CandidateBiometric.fromJson(Map<String, dynamic>.from(json['verification'] as Map));
    } else if (json['verificationData'] is Map) {
      verBio = CandidateBiometric.fromJson(Map<String, dynamic>.from(json['verificationData'] as Map));
    }

    // Merge verification or attendance biometric if present
    if (json['verification'] is Map) {
      final v = json['verification'] as Map;
      for (final k in ['leftThumb', 'rightThumb', 'Left_BMPBase64', 'Right_BMPBase64', 'Left_WSQImage', 'Right_WSQImage', 'Left_ImageQuality', 'Right_ImageQuality', 'livePhoto']) {
        if (v[k] != null && (bioMap[k] == null || bioMap[k].toString().trim().isEmpty)) {
          bioMap[k] = v[k];
        }
      }
    }
    if (json['verificationData'] is Map) {
      final v = json['verificationData'] as Map;
      for (final k in ['leftThumb', 'rightThumb', 'Left_BMPBase64', 'Right_BMPBase64', 'Left_WSQImage', 'Right_WSQImage', 'Left_ImageQuality', 'Right_ImageQuality', 'livePhoto']) {
        if (v[k] != null && (bioMap[k] == null || bioMap[k].toString().trim().isEmpty)) {
          bioMap[k] = v[k];
        }
      }
    }

    // Merge root-level keys if bioMap is missing them
    for (final k in [
      'leftThumb', 'left_thumb', 'leftThumbUrl', 'leftThumbImage', 'Left_BMPBase64', 'Left_WSQImage',
      'rightThumb', 'right_thumb', 'rightThumbUrl', 'rightThumbImage', 'Right_BMPBase64', 'Right_WSQImage',
      'Left_TemplateBase64', 'Right_TemplateBase64', 'leftTemplate', 'rightTemplate', 'templateBase64',
      'Left_ImageQuality', 'Right_ImageQuality', 'leftQuality', 'rightQuality',
      'livePhoto', 'live_photo', 'livePhotoUrl', 'livePhotoImage',
      'biometricJsonUrl', 'biometric_json_url',
    ]) {
      if ((bioMap[k] == null || bioMap[k].toString().trim().isEmpty) && json[k] != null) {
        bioMap[k] = json[k];
      }
    }

    final bio = CandidateBiometric.fromJson(bioMap);

    return Candidate(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      examName: json['examName']?.toString() ?? '',
      examCode: json['examCode']?.toString() ?? '',
      rollNo: json['rollNo']?.toString() ?? '',
      studentId: json['studentId']?.toString() ?? '',
      applicationId: json['applicationId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fatherName: json['fatherName']?.toString() ?? '',
      motherName: json['motherName']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      photo: (json['photo'] ?? json['photoUrl'] ?? json['avatar'])?.toString() ?? '',
      centerId: json['centerId']?.toString() ?? '',
      centerCode: json['centerCode']?.toString() ?? '',
      centerName: json['centerName']?.toString() ?? '',
      centerDistrict: json['centerDistrict']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      attendanceReportId: json['attendanceReportId']?.toString() ?? '',
      lastVerifiedAt: json['lastVerifiedAt']?.toString() ?? '',
      biometricObj: bio,
      verificationBiometric: verBio,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
}
