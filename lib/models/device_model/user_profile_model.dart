
import 'dart:convert';

UserProfileModel userProfileModelFromJson(String str) => UserProfileModel.fromJson(json.decode(str));

String userProfileModelToJson(UserProfileModel data) => json.encode(data.toJson());

class UserProfileModel {
  String? photo;
  String? name;
  String? fatherName;
  String? mobileNumber;
  String? email;
  String? address;
  String? centerName;
  String? centerCode;
  String? aadharFront;
  String? aadharBack;

  UserProfileModel({
    this.name,
    this.photo,
    this.fatherName,
    this.mobileNumber,
    this.email,
    this.address,
    this.centerName,
    this.centerCode,
    this.aadharFront,
    this.aadharBack,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
    name: json["name"],
    photo: json["photo"],
    fatherName: json["father_name"],
    mobileNumber: json["mobile_number"],
    email: json["email"],
    address: json["address"],
    centerName: json["center_name"],
    centerCode: json["center_code"],
    aadharFront: json["aadhar_front"],
    aadharBack: json["aadhar_back"],
  );

  Map<String, dynamic> toJson() => {
    "name": name,
    "photo": photo,
    "father_name": fatherName,
    "mobile_number": mobileNumber,
    "email": email,
    "address": address,
    "center_name": centerName,
    "center_code": centerCode,
    "aadhar_front": aadharFront,
    "aadhar_back": aadharBack,
  };
}
