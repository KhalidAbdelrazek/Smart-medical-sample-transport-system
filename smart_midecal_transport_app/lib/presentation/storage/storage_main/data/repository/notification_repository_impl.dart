import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/data%20source/notification_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/confirm_car_return_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl extends NotificationRepository {
  final NotificationDs notificationDs;
  NotificationRepositoryImpl({required this.notificationDs});

  @override
  Future<Either<Failures, ConfirmCarReturnEntity>> confirmReturnedCar(
    int carId,
  ) {
    return notificationDs.confirmReturnedCar(carId);
  }

  @override
  Future<Either<Failures, ReturnedCarsResponseEntity>> getReturnedCars() {
    return notificationDs.getReturnedCars();
  }
}
