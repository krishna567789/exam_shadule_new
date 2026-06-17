
class AttendanceModel {
  final int? id;
  final String name;
  final String fatherName;
  final String motherName;
  final String email;
  final String mobile;
  final String address;
  final String rollno;
  final String examdate;
  final String shift;
  final String timing;
  final String state;
  final String district;
  final String centerName;
  final String centerCode;
  final String photo;
  final String thumbnail;

  AttendanceModel({
    this.id,
    required this.name,
    required this.fatherName,
    required this.motherName,
    required this.email,
    required this.mobile,
    required this.address,
    required this.rollno,
    required this.examdate,
    required this.shift,
    required this.timing,
    required this.district,
    required this.state,
    required this.centerName,
    required this.centerCode,
    required this.photo,
    required this.thumbnail
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) {
    return AttendanceModel(
      id: json['id'],
      name: json['name'],
      fatherName: json['father_name'],
      motherName: json['mother_name'],
      email: json['email'],
      mobile: json['mobile'],
      address: json['address'],
      rollno: json['rollno'],
      examdate: json['examdate'],
      shift: json['shift'],
      timing: json['timing'],
      state: json["state"],
      district: json["district"],
      centerName: json["center_name"],
      centerCode: json["center_code"],
      photo: json['photo'],
      thumbnail: json['thumbnail']
    );
  }

  Map<String, dynamic> toJson(){
    return {
      'id': id,
      'name': name,
      'father_name': fatherName,
      'mother_name': motherName,
      'email': email,
      'mobile': mobile,
      'address': address,
      'rollno': rollno,
      'examdate': examdate,
      'shift': shift,
      'timing': timing,
      "state": state,
      "district": district,
      "center_name": centerName,
      "center_code": centerCode,
      'photo': photo,
      'thumbnail': thumbnail
    };
  }
}
