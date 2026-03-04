import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/request_sample_response_entity.dart';

class RequestSampleResponseDm extends RequestSampleResponseEntity {
  RequestSampleResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory RequestSampleResponseDm.fromJson(Map<String, dynamic> json) {
    return RequestSampleResponseDm(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? RequestSampleResponseDataDm.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      errors: json['errors'],
    );
  }
}

class RequestSampleResponseDataDm extends RequestSampleResponseData {
  RequestSampleResponseDataDm({
    super.id,
    super.sample,
    super.requestedByName,
    super.roomNumber,
    super.assignedCar,
    super.status,
    super.createdAt,
  });

  factory RequestSampleResponseDataDm.fromJson(Map<String, dynamic> json) {
    return RequestSampleResponseDataDm(
      id: json['id'] as String,
      sample: Sample.fromJson(json['sample'] as Map<String, dynamic>),
      requestedByName: json['requested_by_name'] as String,
      roomNumber: json['room_number'] as String,
      assignedCar: json['assigned_car'],
      status: json['status'] as String,
      createdAt: json['created_at'] as String,
    );
  }
}

class SampleDm extends Sample {
  SampleDm({
    super.id,
    super.sampleCode,
    super.patientName,
    super.patientId,
    super.bloodType,
    super.status,
    super.isInStorage,
    super.createdAt,
    super.updatedAt,
  });

  factory SampleDm.fromJson(Map<String, dynamic> json) {
    return SampleDm(
      id: json['id'] as String,
      sampleCode: json['sample_code'] as String,
      patientName: json['patient_name'] as String,
      patientId: json['patient_id'] as String,
      bloodType: json['blood_type'] as String,
      status: json['status'] as String,
      isInStorage: json['is_in_storage'] as bool,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}
