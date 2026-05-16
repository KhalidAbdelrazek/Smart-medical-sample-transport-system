import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/repository/notification_repository.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/logic/cubit/storage_state.dart';

class StorageMainCubit extends Cubit<StorageState> {
  StorageMainCubit(this._repository) : super(StorageInitial());

  final NotificationRepository _repository;

  Timer? _pollTimer;
  bool _fetchInFlight = false;

  void startPolling() {
    _pollTimer?.cancel();
    unawaited(_fetchReturnedCars(trigger: _FetchTrigger.initial));
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isClosed) return;
      unawaited(_fetchReturnedCars(trigger: _FetchTrigger.periodic));
    });
  }

  /// Manual refresh (e.g. pull-to-refresh).
  Future<void> refresh() => _fetchReturnedCars(trigger: _FetchTrigger.manual);

  Future<void> confirmReturnedCar(int carId) async {
    if (state is ConfirmLoading) return;

    final snapshot = state;
    late final List<ReturnedCarEntity> cars;
    late final DateTime lastUpdated;

    if (snapshot is StorageSuccess) {
      cars = snapshot.cars;
      lastUpdated = snapshot.lastUpdated;
    } else if (snapshot is ConfirmError) {
      cars = snapshot.cars;
      lastUpdated = snapshot.lastUpdated;
    } else if (snapshot is ConfirmLoading) {
      cars = snapshot.cars;
      lastUpdated = snapshot.lastUpdated;
    } else if (snapshot is ConfirmSuccess) {
      cars = snapshot.cars;
      lastUpdated = snapshot.lastUpdated;
    } else {
      return;
    }

    emit(ConfirmLoading(carId: carId, cars: cars, lastUpdated: lastUpdated));

    final result = await _repository.confirmReturnedCar(carId);
    if (isClosed) return;

    if (result.isLeft) {
      emit(
        ConfirmError(
          message: result.left.errorMessage,
          cars: cars,
          lastUpdated: lastUpdated,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      if (!isClosed) {
        emit(StorageSuccess(cars: cars, lastUpdated: lastUpdated));
      }
      return;
    }

    final confirm = result.right;
    emit(
      ConfirmSuccess(
        message: confirm.message,
        cars: cars,
        lastUpdated: lastUpdated,
      ),
    );
    await _fetchReturnedCars(trigger: _FetchTrigger.afterConfirm);
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    _pollTimer = null;
    return super.close();
  }

  Future<void> _fetchReturnedCars({required _FetchTrigger trigger}) async {
    if (_fetchInFlight || isClosed) return;

    final before = state;
    if (before is ConfirmLoading) return;

    final bool showBlockingLoading =
        trigger == _FetchTrigger.initial ||
        (trigger == _FetchTrigger.manual && before is! StorageSuccess);

    if (showBlockingLoading) {
      emit(StorageLoading());
    }

    _fetchInFlight = true;
    try {
      final result = await _repository.getReturnedCars();
      if (isClosed) return;

      result.fold(
        (failure) {
          if (trigger == _FetchTrigger.periodic && before is StorageSuccess) {
            return;
          }
          if (trigger == _FetchTrigger.afterConfirm &&
              before is ConfirmSuccess) {
            emit(
              StorageSuccess(
                cars: before.cars,
                lastUpdated: before.lastUpdated,
              ),
            );
            return;
          }
          emit(StorageError(failure.errorMessage));
        },
        (response) {
          final list = response.data?.returnedCars ?? <ReturnedCarEntity>[];
          emit(
            StorageSuccess(
              cars: List<ReturnedCarEntity>.unmodifiable(list),
              lastUpdated: DateTime.now(),
            ),
          );
        },
      );
    } finally {
      _fetchInFlight = false;
    }
  }
}

enum _FetchTrigger { initial, periodic, manual, afterConfirm }
