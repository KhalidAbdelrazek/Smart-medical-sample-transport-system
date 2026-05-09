import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/confirm_car_return_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failures, ReturnedCarsResponseEntity>> getReturnedCars();
  Future<Either<Failures, ConfirmCarReturnEntity>> confirmReturnedCar(int carId);
}