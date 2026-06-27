class Candidate {
  final String id;
  final String name;
  final String rollNo;
  final String? fatherName;
  final String? motherName;
  final String? email;
  final String? mobile;
  final String? address;
  final String? photo;
  final String? thumbnail;
  final String? localPhotoPath;
  final String? localThumbPath;
  final CandidateStatus status;

  Candidate({
    required this.id,
    required this.name,
    required this.rollNo,
    this.fatherName,
    this.motherName,
    this.email,
    this.mobile,
    this.address,
    this.photo,
    this.thumbnail,
    this.localPhotoPath,
    this.localThumbPath,
    required this.status,
  });
}

enum CandidateStatus { present, absent, pending }
