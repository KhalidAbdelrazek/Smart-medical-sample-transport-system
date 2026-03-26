import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/transport_request_entity.dart';

/// States for the My Requests feature (doctor's own transport requests).
abstract class MyRequestsState {}

class MyRequestsInitial extends MyRequestsState {}

class MyRequestsLoading extends MyRequestsState {}

/// All requests loaded successfully.
class MyRequestsLoaded extends MyRequestsState {
  final List<TransportRequestEntity> requests;
  MyRequestsLoaded({required this.requests});
}

/// API returned an empty list.
class MyRequestsEmpty extends MyRequestsState {}

/// A cancel call is in flight for [cancellingId]; carries the current list
/// so the UI can still render the other cards.
class MyRequestsCancelling extends MyRequestsState {
  final String cancellingId;
  final List<TransportRequestEntity> requests;

  MyRequestsCancelling({
    required this.cancellingId,
    required this.requests,
  });
}

/// Cancel succeeded — carries the old list so the UI can stay visible
/// while the subsequent reload is in progress.
class MyRequestsCancelSuccess extends MyRequestsState {
  final List<TransportRequestEntity> requests;
  MyRequestsCancelSuccess({required this.requests});
}

/// Cancel failed — carries the message AND the list so the builder can
/// keep showing the list while the listener shows a snackbar.
class MyRequestsCancelError extends MyRequestsState {
  final String message;
  final List<TransportRequestEntity> requests;
  MyRequestsCancelError({required this.message, required this.requests});
}

/// Token invalid — triggers logout / re-auth in the UI listener.
class MyRequestsTokenExpired extends MyRequestsState {}

/// General load error.
class MyRequestsError extends MyRequestsState {
  final String message;
  MyRequestsError(this.message);
}
