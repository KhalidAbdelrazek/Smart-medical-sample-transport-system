import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';

class GetRequestsResponseDm extends GetRequestsResponseEntity {
  GetRequestsResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory GetRequestsResponseDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return GetRequestsResponseDm();

    return GetRequestsResponseDm(
      success: json['success'],
      message: json['message'],
      data: (json['data'] as List?)
          ?.map((e) => TransportRequestDm.fromJson(e))
          .toList(),
      errors: json['errors'],
    );
  }
}

class TransportRequestDm extends TransportRequestEntity {
  TransportRequestDm({
    super.id,
    super.sample,
    super.requestedByName,
    super.roomNumber,
    super.assignedCar,
    super.status,
    super.createdAt,
  });

  factory TransportRequestDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TransportRequestDm();

    return TransportRequestDm(
      id: json['id'],
      sample: json['sample'] != null ? SampleDm.fromJson(json['sample']) : null,
      requestedByName: json['requested_by_name'],
      roomNumber: json['room_number'],
      // FIXED: Now correctly parsing the nested Map
      assignedCar: json['assigned_car'] != null
          ? AssignedCarDm.fromJson(json['assigned_car'])
          : null,
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}

class AssignedCarDm extends AssignedCarEntity {
  AssignedCarDm({super.id, super.carNumber, super.status});

  factory AssignedCarDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AssignedCarDm();
    return AssignedCarDm(
      id: json['id'],
      carNumber: json['car_number'],
      status: json['status'],
    );
  }
}

class SampleDm extends SampleEntity {
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

  factory SampleDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return SampleDm();

    return SampleDm(
      id: json['id'],
      sampleCode: json['sample_code'],
      patientName: json['patient_name'],
      patientId: json['patient_id'],
      bloodType: json['blood_type'],
      status: json['status'],
      isInStorage: json['is_in_storage'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }
}
