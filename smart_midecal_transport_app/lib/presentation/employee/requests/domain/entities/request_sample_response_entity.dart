class RequestSampleResponseEntity {
  final bool? success;
  final String? message;
  final RequestSampleResponseData? data;
  final dynamic errors;

  RequestSampleResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });

  factory RequestSampleResponseEntity.fromJson(Map<String, dynamic> json) {
    return RequestSampleResponseEntity(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: RequestSampleResponseData.fromJson(
        json['data'] as Map<String, dynamic>,
      ),
      errors: json['errors'],
    );
  }
}

class RequestSampleResponseData {
  final String? id;
  final Sample? sample;
  final String? requestedByName;
  final String? roomNumber;
  final dynamic assignedCar;
  final String? status;
  final String? createdAt;

  RequestSampleResponseData({
    this.id,
    this.sample,
    this.requestedByName,
    this.roomNumber,
    this.assignedCar,
    this.status,
    this.createdAt,
  });

  factory RequestSampleResponseData.fromJson(Map<String, dynamic> json) {
    return RequestSampleResponseData(
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

class Sample {
  final String? id;
  final String? sampleCode;
  final String? patientName;
  final String? patientId;
  final String? bloodType;
  final String? status;
  final bool? isInStorage;
  final String? createdAt;
  final String? updatedAt;

  Sample({
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

  factory Sample.fromJson(Map<String, dynamic> json) {
    return Sample(
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
