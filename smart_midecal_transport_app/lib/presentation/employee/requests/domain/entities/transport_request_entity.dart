/// Entity representing a single transport request created by the logged-in doctor.
/// Domain layer – no JSON parsing here.
class TransportRequestEntity {
  final String? requestId;
  final String? sampleCode;
  final String? patientName;
  final String? bloodType;
  final String? roomNumber;
  final String? requestStatus;
  final String? assignedCarId;
  final String? createdAt;

  const TransportRequestEntity({
    this.requestId,
    this.sampleCode,
    this.patientName,
    this.bloodType,
    this.roomNumber,
    this.requestStatus,
    this.assignedCarId,
    this.createdAt,
  });
}
