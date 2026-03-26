import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/transport_request_entity.dart';

/// Data model that extends [TransportRequestEntity] and handles JSON deserialization.
/// Parses nested sample object: json["sample"]["sample_code"], etc.
class TransportRequestModel extends TransportRequestEntity {
  const TransportRequestModel({
    super.requestId,
    super.sampleCode,
    super.patientName,
    super.bloodType,
    super.roomNumber,
    super.requestStatus,
    super.assignedCarId,
    super.createdAt,
  });

  factory TransportRequestModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TransportRequestModel();
    final sample = json['sample'] as Map<String, dynamic>?;
    return TransportRequestModel(
      requestId: json['id']?.toString(),
      sampleCode: sample?['sample_code']?.toString(),
      patientName: sample?['patient_name']?.toString(),
      bloodType: sample?['blood_type']?.toString(),
      roomNumber: json['room_number']?.toString(),
      requestStatus: json['status']?.toString(),
      assignedCarId: json['assigned_car']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }
}
