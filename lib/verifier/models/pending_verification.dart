/// One queued verification created while offline (or when submit failed).
/// Stored in Hive box `vse_pending_sync_box` as a JSON string keyed by
/// [clientSyncId] until it is pushed through `/api/verifiers/mobile/sync`.
class PendingVerification {
  final String clientSyncId;
  final String candidateId;
  final String rollNo;
  final String candidateName;
  final String verificationStatus;
  final Map<String, dynamic> payload;
  final String createdAt;

  PendingVerification({
    required this.clientSyncId,
    required this.candidateId,
    required this.rollNo,
    required this.candidateName,
    required this.verificationStatus,
    required this.payload,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'clientSyncId': clientSyncId,
        'candidateId': candidateId,
        'rollNo': rollNo,
        'candidateName': candidateName,
        'verificationStatus': verificationStatus,
        'payload': payload,
        'createdAt': createdAt,
      };

  factory PendingVerification.fromJson(Map<String, dynamic> json) {
    return PendingVerification(
      clientSyncId: json['clientSyncId']?.toString() ?? '',
      candidateId: json['candidateId']?.toString() ?? '',
      rollNo: json['rollNo']?.toString() ?? '',
      candidateName: json['candidateName']?.toString() ?? '',
      verificationStatus: json['verificationStatus']?.toString() ?? '',
      payload: json['payload'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['payload'])
          : <String, dynamic>{},
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
