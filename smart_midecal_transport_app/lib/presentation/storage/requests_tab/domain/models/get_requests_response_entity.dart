class GetRequestsResponseEntity {
  final bool? success;
  final String? message;
  final List<TransportRequestEntity>? data;
  final dynamic errors;

  GetRequestsResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}

class TransportRequestEntity {
  final String? id;
  final SampleEntity? sample;
  final String? requestedByName;
  final String? roomNumber;
  final AssignedCarEntity? assignedCar; // Changed from String?
  final String? status;
  final String? createdAt;

  TransportRequestEntity({
    this.id,
    this.sample,
    this.requestedByName,
    this.roomNumber,
    this.assignedCar,
    this.status,
    this.createdAt,
  });
}

class AssignedCarEntity {
  final int? id;
  final String? carNumber;
  final String? status;
  final String? createdAt;

  AssignedCarEntity({this.id, this.carNumber, this.status, this.createdAt});
}

class SampleEntity {
  final String? id;
  final String? sampleCode;
  final String? patientName;
  final String? patientId;
  final String? bloodType;
  final String? status;
  final bool? isInStorage;
  final String? createdAt;
  final String? updatedAt;

  SampleEntity({
    this.id,
    this.sampleCode,
    this.patientName,
    this.patientId,
    this.bloodType,
    this.status,
    this.isInStorage,
    this.createdAt,
    this.updatedAt,
  });
}