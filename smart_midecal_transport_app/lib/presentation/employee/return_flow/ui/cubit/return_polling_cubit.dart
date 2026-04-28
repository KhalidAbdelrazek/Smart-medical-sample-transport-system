import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/data/return_flow_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/domain/entities/return_status_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/ui/cubit/return_polling_state.dart';

class ReturnPollingCubit extends Cubit<ReturnPollingState> {
  final ReturnFlowRemoteDataSource _remoteDataSource;
  Timer? _pollingTimer;
  bool _pollInProgress = false;

  ReturnPollingCubit(this._remoteDataSource) : super(ReturnPollingState.initial());

  void startPolling({Duration interval = const Duration(seconds: 4)}) {
    _pollingTimer?.cancel();
    _pollOnce();
    _pollingTimer = Timer.periodic(interval, (_) => _pollOnce());
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _pollOnce() async {
    if (_pollInProgress) return;
    _pollInProgress = true;
    final result = await _remoteDataSource.fetchReturnStatus();

    result.fold(
      (failure) {
        if (failure is TokenExpiredFailure) {
          emit(state.copyWith(tokenExpired: true, toastMessage: failure.errorMessage));
        } else if (!state.hasBlockingPopup) {
          emit(state.copyWith(toastMessage: failure.errorMessage));
        }
      },
      (rows) {
        final grouped = <String, List<ReturnStatusEntity>>{};
        for (final row in rows) {
          final batchId = row.batchId;
          if (batchId == null || batchId.isEmpty) continue;
          grouped.putIfAbsent(batchId, () => []).add(row);
        }

        if (state.activeBatchId != null) {
          final existingBatchRows = grouped[state.activeBatchId];
          if (existingBatchRows != null && existingBatchRows.isNotEmpty) {
            emit(
              state.copyWith(
                activeSamples: existingBatchRows,
                isConfirming: false,
                clearToast: true,
              ),
            );
          }
          _pollInProgress = false;
          return;
        }

        if (grouped.isEmpty) {
          emit(state.copyWith(clearBatch: true, isConfirming: false, clearToast: true));
          _pollInProgress = false;
          return;
        }

        final nextBatchId = grouped.keys.first;
        emit(
          state.copyWith(
            activeBatchId: nextBatchId,
            activeSamples: grouped[nextBatchId] ?? const [],
            isConfirming: false,
            clearToast: true,
          ),
        );
      },
    );
    _pollInProgress = false;
  }

  Future<void> confirmHandoff() async {
    final batchId = state.activeBatchId;
    if (batchId == null || batchId.isEmpty || state.isConfirming) return;

    emit(state.copyWith(isConfirming: true));
    final result = await _remoteDataSource.confirmReturn(batchId);

    result.fold(
      (failure) {
        if (failure is TokenExpiredFailure) {
          emit(
            state.copyWith(
              isConfirming: false,
              tokenExpired: true,
              toastMessage: failure.errorMessage,
            ),
          );
          return;
        }
        emit(
          state.copyWith(
            isConfirming: false,
            toastMessage: failure.errorMessage,
          ),
        );
      },
      (_) {
        emit(
          state.copyWith(
            clearBatch: true,
            isConfirming: false,
            toastMessage: 'return_popup.confirm_success',
          ),
        );
        _pollOnce();
      },
    );
  }

  void clearToast() {
    if (state.toastMessage == null) return;
    emit(state.copyWith(clearToast: true));
  }

  void clearTokenExpired() {
    if (!state.tokenExpired) return;
    emit(state.copyWith(tokenExpired: false));
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
