import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/repos/my_request_repo.dart';
import 'my_requests_state.dart';

/// Cubit for the "My Requests" tab — shows the doctor's own transport requests
/// and allows cancelling pending ones.
@injectable
class MyRequestsCubit extends Cubit<MyRequestsState> {
  final MyRequestsRepository _repository;

  List<TransportMyRequestEntity> _requests = [];

  MyRequestsCubit(this._repository) : super(MyRequestsInitial());

  // ── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadMyRequests() async {
    emit(MyRequestsLoading());
    final result = await _repository.getMyRequests();
    result.fold(
      (failure) {
        if (failure is TokenExpiredFailure) {
          emit(MyRequestsTokenExpired());
          return;
        }
        emit(MyRequestsError(failure.errorMessage));
      },
      (requests) {
        _requests = requests;
        if (requests.isEmpty) {
          emit(MyRequestsEmpty());
        } else {
          emit(MyRequestsLoaded(requests: List.unmodifiable(_requests)));
        }
      },
    );
  }

  /// Pull-to-refresh — same as load.
  Future<void> refresh() => loadMyRequests();

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancelRequest(String requestId) async {
    // Show per-card spinner while call is in flight.
    emit(
      MyRequestsCancelling(
        cancellingId: requestId,
        requests: List.unmodifiable(_requests),
      ),
    );

    final result = await _repository.cancelRequest(requestId);
    result.fold(
      (failure) {
        if (failure is TokenExpiredFailure) {
          emit(MyRequestsTokenExpired());
          return;
        }
        // Restore list + surface the error through a listener-catchable state.
        emit(
          MyRequestsCancelError(
            message: failure.errorMessage,
            requests: List.unmodifiable(_requests),
          ),
        );
      },
      (_) async {
        // Notify listener (for success snackbar), then reload from server.
        emit(MyRequestsCancelSuccess(requests: List.unmodifiable(_requests)));
        await loadMyRequests();
      },
    );
  }
}
