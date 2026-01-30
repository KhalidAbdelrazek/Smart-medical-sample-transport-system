import '../domain/request_models.dart';

/// States for Blood Bags sub-tab
abstract class BloodBagsState {}

class BloodBagsInitial extends BloodBagsState {}

class BloodBagsLoading extends BloodBagsState {}

class BloodBagsLoaded extends BloodBagsState {
  final List<BloodBagRequest> pendingRequests;
  final List<BloodBagRequest> addedToCarRequests;
  final TransportCar car;

  BloodBagsLoaded({
    required this.pendingRequests,
    required this.addedToCarRequests,
    required this.car,
  });

  int get pendingCount => pendingRequests.length;
  int get addedCount => addedToCarRequests.length;
}

class BloodBagsError extends BloodBagsState {
  final String message;
  BloodBagsError(this.message);
}
