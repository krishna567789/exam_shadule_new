class Candidate {
  final String id;
  final String name;
  final String rollNo;
  final CandidateStatus status;

  Candidate({
    required this.id,
    required this.name,
    required this.rollNo,
    required this.status,
  });
}

enum CandidateStatus { present, absent, pending }
