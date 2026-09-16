class OperatorProfileResponse {
  final bool status;
  final bool profileCompleted;
  final OperatorProfileData? data;

  OperatorProfileResponse({
    required this.status,
    required this.profileCompleted,
    this.data,
  });

  factory OperatorProfileResponse.fromJson(Map<String, dynamic> json) {
    return OperatorProfileResponse(
      status: json['status'] ?? false,
      profileCompleted: json['profileCompleted'] ?? false,
      data: json['data'] != null ? OperatorProfileData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'profileCompleted': profileCompleted,
      'data': data?.toJson(),
    };
  }
}

class OperatorProfileData {
  final OperatorProfile? profile;

  OperatorProfileData({this.profile});

  factory OperatorProfileData.fromJson(Map<String, dynamic> json) {
    return OperatorProfileData(
      profile: json['profile'] != null ? OperatorProfile.fromJson(json['profile']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profile': profile?.toJson(),
    };
  }
}

class OperatorProfile {
  final String id;
  final String registrarId;
  final String operatorId;
  final String name;
  final String fatherName;
  final String mobileNumber;
  final String email;
  final String address;
  final String role;
  final String state;
  final String city;
  final String aadharFront;
  final String aadharBack;
  final String photo;
  final String createdAt;
  final String updatedAt;

  OperatorProfile({
    this.id = '',
    this.registrarId = '',
    this.operatorId = '',
    this.name = '',
    this.fatherName = '',
    this.mobileNumber = '',
    this.email = '',
    this.address = '',
    this.role = '',
    this.state = '',
    this.city = '',
    this.aadharFront = '',
    this.aadharBack = '',
    this.photo = '',
    this.createdAt = '',
    this.updatedAt = '',
  });

  factory OperatorProfile.fromJson(Map<String, dynamic> json) {
    return OperatorProfile(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      registrarId: json['registrarId']?.toString() ?? '',
      operatorId: json['operatorId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      fatherName: json['fatherName']?.toString() ?? '',
      mobileNumber: json['mobileNumber']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      role: json['role']?.toString() ?? 'operator',
      state: json['state']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      aadharFront: json['aadharFront']?.toString() ?? '',
      aadharBack: json['aadharBack']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'registrarId': registrarId,
      'operatorId': operatorId,
      'name': name,
      'fatherName': fatherName,
      'mobileNumber': mobileNumber,
      'email': email,
      'address': address,
      'role': role,
      'state': state,
      'city': city,
      'aadharFront': aadharFront,
      'aadharBack': aadharBack,
      'photo': photo,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
