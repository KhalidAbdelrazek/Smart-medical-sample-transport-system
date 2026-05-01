class ReturnRequestEntity {
  final String id;
  final ReturnRequestSampleEntity sample;
  final ReturnRequestDoctorEntity requestedBy;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ReturnRequestEntity({
    required this.id,
    required this.sample,
    required this.requestedBy,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReturnRequestEntity.fromJson(Map<String, dynamic> json) {
    return ReturnRequestEntity(
      id: json['id'] as String,
      sample: ReturnRequestSampleEntity.fromJson(
        json['sample'] as Map<String, dynamic>,
      ),
      requestedBy: ReturnRequestDoctorEntity.fromJson(
        json['requested_by'] as Map<String, dynamic>,
      ),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sample': sample.toJson(),
      'requested_by': requestedBy.toJson(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class ReturnRequestSampleEntity {
  final String id;
  final String patientName;
  final String sampleCode;
  final String bloodType;
  final String status;

  const ReturnRequestSampleEntity({
    required this.id,
    required this.patientName,
    required this.sampleCode,
    required this.bloodType,
    required this.status,
  });

  factory ReturnRequestSampleEntity.fromJson(Map<String, dynamic> json) {
    return ReturnRequestSampleEntity(
      id: json['id'] as String,
      patientName: json['patient_name'] as String,
      sampleCode: json['sample_code'] as String? ?? '',
      bloodType: json['blood_type'] as String,
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_name': patientName,
      'sample_code': sampleCode,
      'blood_type': bloodType,
      'status': status,
    };
  }
}

class ReturnRequestDoctorEntity {
  final String id;
  final String name;
  final String email;

  const ReturnRequestDoctorEntity({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ReturnRequestDoctorEntity.fromJson(Map<String, dynamic> json) {
    return ReturnRequestDoctorEntity(
      id: json['id'] as String,
      name: json['full_name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'full_name': name, 'email': email};
  }
}
