import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/add_to_car_response_entity.dart';

class AddToCarResponseDm extends AddToCarResponseEntity {
  AddToCarResponseDm({super.success, super.message, super.data, super.errors});

  factory AddToCarResponseDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return AddToCarResponseDm();

    return AddToCarResponseDm(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? TransportRequestDm.fromJson(json['data'])
          : null,
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
      assignedCar: json['assigned_car'] != null
          ? CarDm.fromJson(json['assigned_car'])
          : null,
      status: json['status'],
      createdAt: json['created_at'],
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

class CarDm extends CarEntity {
  CarDm({super.id, super.carNumber, super.status, super.createdAt});

  factory CarDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return CarDm();

    return CarDm(
      id: json['id'],
      carNumber: json['car_number'],
      status: json['status'],
      createdAt: json['created_at'],
    );
  }
}
