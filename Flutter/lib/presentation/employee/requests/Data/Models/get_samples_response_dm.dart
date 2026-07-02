import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';

class GetSamplesResponseDm extends SamplesResponseEntity {
  GetSamplesResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  // from json
  factory GetSamplesResponseDm.fromJson(Map<String, dynamic> json) {
    return GetSamplesResponseDm(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => SampleEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: json['errors'],
    );
  }
}

class SampleDm extends SampleEntity {
  SampleDm({
    super.id,
    super.sampleCode,
    super.patientName,
    super.status,
    super.isInStorage,
  });

  // from json
  factory SampleDm.fromJson(Map<String, dynamic> json) {
    return SampleDm(
      id: json['id'] as String,
      sampleCode: json['sample_code'] as String,
      patientName: json['patient_name'] as String,
      status: json['status'] as String,
      isInStorage: json['is_in_storage'] as bool,
    );
  }
}
