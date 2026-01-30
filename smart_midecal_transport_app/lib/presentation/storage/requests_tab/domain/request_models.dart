/// Domain models for Requests Tab
/// Blood bag and blood sample requests with car management

/// Status of a request
enum RequestStatus { pending, addedToCar }

/// Source of a request
enum RequestSource { lab, operationRoom }

/// Blood type enum
enum BloodType {
  aPositive('A+'),
  aNegative('A-'),
  bPositive('B+'),
  bNegative('B-'),
  abPositive('AB+'),
  abNegative('AB-'),
  oPositive('O+'),
  oNegative('O-');

  final String label;
  const BloodType(this.label);
}

/// Blood bag request model
class BloodBagRequest {
  final String id;
  final BloodType bloodType;
  final int quantity;
  final RequestSource source;
  final String sourceDetail;
  final RequestStatus status;

  const BloodBagRequest({
    required this.id,
    required this.bloodType,
    required this.quantity,
    required this.source,
    required this.sourceDetail,
    this.status = RequestStatus.pending,
  });

  BloodBagRequest copyWith({
    String? id,
    BloodType? bloodType,
    int? quantity,
    RequestSource? source,
    String? sourceDetail,
    RequestStatus? status,
  }) {
    return BloodBagRequest(
      id: id ?? this.id,
      bloodType: bloodType ?? this.bloodType,
      quantity: quantity ?? this.quantity,
      source: source ?? this.source,
      sourceDetail: sourceDetail ?? this.sourceDetail,
      status: status ?? this.status,
    );
  }
}

/// Blood sample request model
class BloodSampleRequest {
  final String id;
  final String patientId;
  final int sampleCount;
  final RequestSource source;
  final String sourceDetail;
  final RequestStatus status;

  const BloodSampleRequest({
    required this.id,
    required this.patientId,
    required this.sampleCount,
    required this.source,
    required this.sourceDetail,
    this.status = RequestStatus.pending,
  });

  BloodSampleRequest copyWith({
    String? id,
    String? patientId,
    int? sampleCount,
    RequestSource? source,
    String? sourceDetail,
    RequestStatus? status,
  }) {
    return BloodSampleRequest(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      sampleCount: sampleCount ?? this.sampleCount,
      source: source ?? this.source,
      sourceDetail: sourceDetail ?? this.sourceDetail,
      status: status ?? this.status,
    );
  }
}

/// Transport car model
class TransportCar {
  final int maxCapacity;
  final int currentLoad;

  const TransportCar({this.maxCapacity = 5, this.currentLoad = 0});

  bool get isFull => currentLoad >= maxCapacity;
  bool get isEmpty => currentLoad == 0;
  int get availableSpace => maxCapacity - currentLoad;

  TransportCar copyWith({int? maxCapacity, int? currentLoad}) {
    return TransportCar(
      maxCapacity: maxCapacity ?? this.maxCapacity,
      currentLoad: currentLoad ?? this.currentLoad,
    );
  }
}
