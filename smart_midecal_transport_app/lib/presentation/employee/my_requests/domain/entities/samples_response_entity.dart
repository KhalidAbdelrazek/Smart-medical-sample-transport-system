class SamplesMyResponseEntity {
  final bool? success;
  final String? message;
  final List<SampleEntity>? data;
  final dynamic errors;

  SamplesMyResponseEntity({this.success, this.message, this.data, this.errors});

  // from json
  factory SamplesMyResponseEntity.fromJson(Map<String, dynamic> json) {
    return SamplesMyResponseEntity(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => SampleEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: json['errors'],
    );
  }
}

class SampleEntity {
  final String? id;
  final String? sampleCode;
  final String? patientName;
  final String? status;
  final bool? isInStorage;

  SampleEntity({
    this.id,
    this.sampleCode,
    this.patientName,
    this.status,
    this.isInStorage,
  });

  // from json
  factory SampleEntity.fromJson(Map<String, dynamic> json) {
    return SampleEntity(
      id: json['id'] as String,
      sampleCode: json['sample_code'] as String,
      patientName: json['patient_name'] as String,
      status: json['status'] as String,
      isInStorage: json['is_in_storage'] as bool,
    );
  }
}
