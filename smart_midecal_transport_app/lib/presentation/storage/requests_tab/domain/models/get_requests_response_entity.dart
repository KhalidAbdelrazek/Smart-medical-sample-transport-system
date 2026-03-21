class GetRequestsResponseEntity {
  final bool? success;
  final String? message;
  final List<TransportRequestEntity>? data;
  // final ErrorEntity? errors;
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
  final String? assignedCar;
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

// class ErrorEntity {
//   final String? detail;
//   final String? code;
//   final List<TokenMessageEntity>? messages;

//   ErrorEntity({this.detail, this.code, this.messages});
// }

// class TokenMessageEntity {
//   final String? tokenClass;
//   final String? tokenType;
//   final String? message;

//   TokenMessageEntity({this.tokenClass, this.tokenType, this.message});
// }
