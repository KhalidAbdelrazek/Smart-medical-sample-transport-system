import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';

abstract class NotificationDataSource {
  Future<Either<Failures, NotificationResponseEntity>> getNotifications();
  Future<Either<Failures, String?>> confirmDelivery({required String requestId});
  Future<Either<Failures, String?>> rejectDelivery({required String requestId});
}