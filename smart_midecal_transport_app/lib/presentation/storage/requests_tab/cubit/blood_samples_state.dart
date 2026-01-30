import '../domain/request_models.dart';

/// States for Blood Samples sub-tab
abstract class BloodSamplesState {}

class BloodSamplesInitial extends BloodSamplesState {}

class BloodSamplesLoading extends BloodSamplesState {}

class BloodSamplesLoaded extends BloodSamplesState {
  final List<BloodSampleRequest> pendingRequests;
  final List<BloodSampleRequest> addedToCarRequests;
  final TransportCar car;

  BloodSamplesLoaded({
    required this.pendingRequests,
    required this.addedToCarRequests,
    required this.car,
  });

  int get pendingCount => pendingRequests.length;
  int get addedCount => addedToCarRequests.length;
}

class BloodSamplesError extends BloodSamplesState {
  final String message;
  BloodSamplesError(this.message);
}
