import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';

/// States for Blood Samples sub-tab
abstract class BloodSamplesState {}

class BloodSamplesInitial extends BloodSamplesState {}

class BloodSamplesLoading extends BloodSamplesState {}

/// Loaded state – carries the full list of transport requests from the API.
class BloodSamplesLoaded extends BloodSamplesState {
  final List<TransportRequestEntity> requests;

  /// When non-null, this request ID has an in-progress addToCar call.
  final String? actionLoadingId;

  BloodSamplesLoaded({required this.requests, this.actionLoadingId});

  int get pendingCount => requests
      .where(
        (r) =>
            (r.status?.toUpperCase() == 'PENDING') ||
            (r.status?.toUpperCase() == 'REQUESTED'),
      )
      .length;
}

class BloodSamplesError extends BloodSamplesState {
  final String message;
  BloodSamplesError(this.message);
}

/// Emitted after a successful addToCar so the view can show a SnackBar.
class BloodSamplesActionSuccess extends BloodSamplesState {
  final String message;
  final List<TransportRequestEntity> requests;

  BloodSamplesActionSuccess({required this.message, required this.requests});
}

/// Emitted when addToCar / dispatchCar fails so the view can show a SnackBar.
class BloodSamplesActionError extends BloodSamplesState {
  final String message;
  final List<TransportRequestEntity> requests;

  BloodSamplesActionError({required this.message, required this.requests});
}
