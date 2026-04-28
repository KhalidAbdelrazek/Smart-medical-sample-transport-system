class ReturnStatusEntity {
  final String requestId;
  final String? batchId;
  final String sampleId;
  final String sampleName;
  final String status;

  const ReturnStatusEntity({
    required this.requestId,
    required this.batchId,
    required this.sampleId,
    required this.sampleName,
    required this.status,
  });

  factory ReturnStatusEntity.fromJson(Map<String, dynamic> json) {
    return ReturnStatusEntity(
      requestId: json['request_id']?.toString() ?? '',
      batchId: json['batch_id']?.toString(),
      sampleId: json['sample_id']?.toString() ?? '',
      sampleName: json['sample_name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
    );
  }
}
