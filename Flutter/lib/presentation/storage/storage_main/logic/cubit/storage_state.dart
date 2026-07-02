import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';

/// Domain car row from returned-cars API (alias for readability in UI contracts).
typedef StorageCar = ReturnedCarEntity;

abstract class StorageState {}

class StorageInitial extends StorageState {}

class StorageLoading extends StorageState {}

class StorageSuccess extends StorageState {
  StorageSuccess({required this.cars, required this.lastUpdated});

  final List<StorageCar> cars;
  final DateTime lastUpdated;
}

class StorageError extends StorageState {
  StorageError(this.message);

  final String message;
}

/// Confirm request in flight; list stays visible.
class ConfirmLoading extends StorageState {
  ConfirmLoading({
    required this.carId,
    required this.cars,
    required this.lastUpdated,
  });

  final int carId;
  final List<StorageCar> cars;
  final DateTime lastUpdated;
}

/// Confirm succeeded — listener can show feedback before list refresh completes.
class ConfirmSuccess extends StorageState {
  ConfirmSuccess({required this.cars, required this.lastUpdated, this.message});

  final List<StorageCar> cars;
  final DateTime lastUpdated;
  final String? message;
}

/// Confirm failed — listener can show error; [cars] preserved for the UI.
class ConfirmError extends StorageState {
  ConfirmError({
    required this.message,
    required this.cars,
    required this.lastUpdated,
  });

  final String message;
  final List<StorageCar> cars;
  final DateTime lastUpdated;
}
