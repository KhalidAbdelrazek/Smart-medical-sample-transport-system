
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';

/// Data model that extends [TransportMyRequestEntity] and handles JSON deserialization.
/// Parses nested sample object: json["sample"]["sample_code"], etc.
class TransportMyRequestModel extends TransportMyRequestEntity {
  const TransportMyRequestModel({
    super.requestId,
    super.sampleCode,
    super.patientName,
    super.bloodType,
    super.roomNumber,
    super.requestStatus,
    super.assignedCarId,
    super.createdAt,
  });

  factory TransportMyRequestModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const TransportMyRequestModel();
    final sample = json['sample'] as Map<String, dynamic>?;
    return TransportMyRequestModel(
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
