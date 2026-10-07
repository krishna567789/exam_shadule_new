/// Enrolled biometric reference for a candidate (URLs returned by backend).
class CandidateBiometric {
  final String biometricJsonUrl;
  final String leftThumb;
  final String rightThumb;
  final String livePhoto;
  final String biometricTime;
  final String attendanceTime;
  final String capturedDevice;
  final String status;

  CandidateBiometric({
    this.biometricJsonUrl = '',
    this.leftThumb = '',
    this.rightThumb = '',
    this.livePhoto = '',
    this.biometricTime = '',
    this.attendanceTime = '',
    this.capturedDevice = '',
    this.status = '',
  });

  factory CandidateBiometric.fromJson(Map<String, dynamic> json) {
    return CandidateBiometric(
      biometricJsonUrl: json['biometricJsonUrl']?.toString() ?? '',
      leftThumb: json['leftThumb']?.toString() ?? '',
      rightThumb: json['rightThumb']?.toString() ?? '',
      livePhoto: json['livePhoto']?.toString() ?? '',
      biometricTime: json['biometricTime']?.toString() ?? '',
      attendanceTime: json['attendanceTime']?.toString() ?? '',
      capturedDevice: json['capturedDevice']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'biometricJsonUrl': biometricJsonUrl,
        'leftThumb': leftThumb,
        'rightThumb': rightThumb,
        'livePhoto': livePhoto,
        'biometricTime': biometricTime,
        'attendanceTime': attendanceTime,
        'capturedDevice': capturedDevice,
        'status': status,
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
  }) : biometric = biometricObj ?? CandidateBiometric();

  factory Candidate.fromJson(Map<String, dynamic> json) {
    final bio = json['biometric'] is Map<String, dynamic>
        ? CandidateBiometric.fromJson(json['biometric'] as Map<String, dynamic>)
        : null;
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
      photo: json['photo']?.toString() ?? '',
      centerId: json['centerId']?.toString() ?? '',
      centerCode: json['centerCode']?.toString() ?? '',
      centerName: json['centerName']?.toString() ?? '',
      centerDistrict: json['centerDistrict']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      attendanceReportId: json['attendanceReportId']?.toString() ?? '',
      lastVerifiedAt: json['lastVerifiedAt']?.toString() ?? '',
      biometricObj: bio,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
}
