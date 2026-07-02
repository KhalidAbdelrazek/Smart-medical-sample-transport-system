import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';

abstract class NotificationRepository {
  Future<Either<Failures, NotificationResponseEntity>> getNotifications();
  Future<Either<Failures, String?>> confirmDelivery({
    required String requestId,
  });
  Future<Either<Failures, String?>> rejectDelivery({required String requestId});

  /// Called after the user accepts a delivery.
  /// [sampleCodes] is the list of selected returnable sample codes,
  /// or an empty list if the user chose not to return any samples.
  Future<Either<Failures, String?>> confirmReturnHandoff({
    required List<String> sampleCodes,
  });
}
