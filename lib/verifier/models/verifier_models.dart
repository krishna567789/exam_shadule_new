/// Verifier account + assignment (exam/center are fixed by the backend).
class VerifierProfile {
  final String id;
  final String name;
  final String fatherName;
  final String mobileNumber;
  final String email;
  final String address;
  final String state;
  final String city;
  final String photo;
  final String aadharFront;
  final String aadharBack;

  VerifierProfile({
    this.id = '',
    this.name = '',
    this.fatherName = '',
    this.mobileNumber = '',
    this.email = '',
    this.address = '',
    this.state = '',
    this.city = '',
    this.photo = '',
    this.aadharFront = '',
    this.aadharBack = '',
  });

  factory VerifierProfile.fromJson(Map<String, dynamic> json) {
    return VerifierProfile(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fatherName: json['fatherName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      aadharFront: json['aadharFront']?.toString() ?? '',
      aadharBack: json['aadharBack']?.toString() ?? '',
    );
  }

  bool get isComplete =>
      name.isNotEmpty &&
      fatherName.isNotEmpty &&
      mobileNumber.isNotEmpty &&
      email.isNotEmpty &&
      state.isNotEmpty &&
      city.isNotEmpty &&
      photo.isNotEmpty &&
      aadharFront.isNotEmpty &&
      aadharBack.isNotEmpty;
}

class VerifierSession {
  final String id;
  final String verifierId;
  final String examId;
  final String examName;
  final String examCode;
  final String centerId;
  final String centerCode;
  final String centerName;
  final String centerDistrict;
  final String centerState;
  final String centerFullAddress;
  final bool profileCompleted;
  final bool isActive;
  final VerifierProfile profile;

  VerifierSession({
    this.id = '',
    this.verifierId = '',
    this.examId = '',
    this.examName = '',
    this.examCode = '',
    this.centerId = '',
    this.centerCode = '',
    this.centerName = '',
    this.centerDistrict = '',
    this.centerState = '',
    this.centerFullAddress = '',
    this.profileCompleted = false,
    this.isActive = false,
    VerifierProfile? profileObj,
  }) : profile = profileObj ?? VerifierProfile();

  /// Accepts the `data` object from /login or /mobile/me or /profile/check.
  /// /login returns the verifier fields directly on `data`;
  /// /me and /profile/check nest them under `data.verifier`.
  factory VerifierSession.fromJson(Map<String, dynamic> json) {
    final v = json['verifier'] is Map<String, dynamic>
        ? json['verifier'] as Map<String, dynamic>
        : json;
    final profileMap = v['profile'] is Map<String, dynamic>
        ? v['profile'] as Map<String, dynamic>
        : <String, dynamic>{};

    return VerifierSession(
      id: v['id']?.toString() ?? '',
      verifierId: v['verifierId']?.toString() ?? '',
      examId: v['examId']?.toString() ?? '',
      examName: v['examName']?.toString() ?? '',
      examCode: v['examCode']?.toString() ?? '',
      centerId: v['centerId']?.toString() ?? '',
      centerCode: v['centerCode']?.toString() ?? '',
      centerName: v['centerName']?.toString() ?? '',
      centerDistrict: v['centerDistrict']?.toString() ?? '',
      centerState: v['centerState']?.toString() ?? '',
      centerFullAddress: v['centerFullAddress']?.toString() ?? '',
      profileCompleted:
          (v['profileCompleted'] ?? json['profileCompleted'] ?? false) == true,
      isActive: (v['isActive'] ?? true) == true,
      profileObj: VerifierProfile.fromJson(profileMap),
    );
  }
}

class DashboardSummary {
  final int total;
  final int pending;
  final int verified;
  final int rejected;
  final int recheck;

  DashboardSummary({
    this.total = 0,
    this.pending = 0,
    this.verified = 0,
    this.rejected = 0,
    this.recheck = 0,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    int parse(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DashboardSummary(
      total: parse(json['total']),
      pending: parse(json['pending']),
      verified: parse(json['verified']),
      rejected: parse(json['rejected']),
      recheck: parse(json['recheck']),
    );
  }
}
