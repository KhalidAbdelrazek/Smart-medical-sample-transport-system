import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/repository/requests_repository.dart';
import 'blood_samples_state.dart';

/// Cubit for the Blood Samples requests tab.
/// Delegates all data operations to [RequestsRepository] — no business logic inside.
@injectable
class BloodSamplesCubit extends Cubit<BloodSamplesState> {
  final RequestsRepository _repository;

  BloodSamplesCubit(this._repository) : super(BloodSamplesInitial());

  List<TransportRequestEntity> _requests = [];

  // ── Public API ────────────────────────────────────────────────────────────

  /// Fetch all storage requests from the API.
  Future<void> loadRequests() async {
    emit(BloodSamplesLoading());
    final result = await _repository.getRequests();
    result.fold((failure) => emit(BloodSamplesError(failure.errorMessage)), (
      response,
    ) {
      _requests = response.data ?? [];
      emit(BloodSamplesLoaded(requests: List.unmodifiable(_requests)));
    });
  }

  /// Pull-to-refresh — same as loadRequests but may be called while loaded.
  Future<void> refresh() => loadRequests();

  /// Add a sample to the transport car via the API.
  Future<void> addToCar(String requestId, String sampleCode) async {
    // Show per-card loading spinner
    emit(
      BloodSamplesLoaded(
        requests: List.unmodifiable(_requests),
        actionLoadingId: requestId,
      ),
    );

    final result = await _repository.addToCar(sampleCode);
    result.fold(
      (failure) => emit(
        BloodSamplesActionError(
          message: failure.errorMessage,
          requests: List.unmodifiable(_requests),
        ),
      ),
      (response) {
        // Re-fetch to get the updated status from the server
        _refreshAfterAction(
          'employee.sample_added_to_car'.tr(),
        );
      },
    );
  }

  /// Dispatch the transport car via the API.
  Future<void> dispatchCar() async {
    emit(
      BloodSamplesLoaded(
        requests: List.unmodifiable(_requests),
        actionLoadingId: 'dispatch',
      ),
    );

    final result = await _repository.dispatchCar();
    result.fold(
      (failure) => emit(
        BloodSamplesActionError(
          message: failure.errorMessage,
          requests: List.unmodifiable(_requests),
        ),
      ),
      (response) {
        _refreshAfterAction(
          response.message ?? 'status.car_dispatched_successfully'.tr(),
        );
      },
    );
  }

  /// Remove a loaded sample from the car via the API.
  Future<void> removeFromCar(String requestId) async {
    // Show per-card loading spinner
    emit(
      BloodSamplesLoaded(
        requests: List.unmodifiable(_requests),
        actionLoadingId: requestId,
      ),
    );

    final result = await _repository.removeFromCar(requestId);
    result.fold(
      (failure) => emit(
        BloodSamplesActionError(
          message: failure.errorMessage,
          requests: List.unmodifiable(_requests),
        ),
      ),
      (response) {
        _refreshAfterAction('employee.sample_removed_from_car'.tr());
      },
    );
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  Future<void> _refreshAfterAction(String successMessage) async {
    final result = await _repository.getRequests();
    result.fold(
      (failure) {
        // Even on refresh failure, keep old list and show success
        emit(
          BloodSamplesActionSuccess(
            message: successMessage,
            requests: List.unmodifiable(_requests),
          ),
        );
      },
      (response) {
        _requests = response.data ?? [];
        emit(
          BloodSamplesActionSuccess(
            message: successMessage,
            requests: List.unmodifiable(_requests),
          ),
        );
      },
    );
  }
}
