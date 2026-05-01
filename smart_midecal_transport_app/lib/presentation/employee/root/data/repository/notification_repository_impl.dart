import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/data/data%20source/notification_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/repository/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {

  final NotificationDataSource notificationDataSource;
  
  NotificationRepositoryImpl(this.notificationDataSource);
  @override
  Future<Either<Failures, NotificationResponseEntity>> getNotifications() {
    return notificationDataSource.getNotifications();
  }
  
  @override
  Future<Either<Failures, String?>> confirmDelivery({required String requestId}) {
    return notificationDataSource.confirmDelivery(requestId: requestId);
  }
  
  @override
  Future<Either<Failures, String?>> rejectDelivery({required String requestId}) {
    return notificationDataSource.rejectDelivery(requestId: requestId);
  }
}