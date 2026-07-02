import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

abstract class RestrictionsDataSource {
  Future<Either<Failures, RestrictionsEntity>> getRestrictionsStatus({
    required String type,
  });

  Future<Either<Failures, bool>> restrictDoctorSamples({
    required RestrictionType type,
    List<String> userIds,
    String reason,
  });

  Future<Either<Failures, bool>> restrictStorageSamples({
    required RestrictionType type,
    List<String> userIds,
    String reason,
  });

  Future<Either<Failures, bool>> restrictTransportCar({
    required bool status,
    String reason,
  });
}
