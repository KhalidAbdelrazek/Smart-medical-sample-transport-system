import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

abstract class RestrictionsRepository {
  /// Fetch current restrictions status for doctors or storage employees.
  /// [type] — 'doctor' | 'storage'
  Future<Either<Failures, RestrictionsEntity>> getRestrictionsStatus({
    required String type,
  });

  /// Restrict / un-restrict doctor sample requests.
  Future<Either<Failures, bool>> restrictDoctorSamples({
    required RestrictionType type,
    List<String> userIds,
    String reason,
  });

  /// Restrict / un-restrict storage sample loading.
  Future<Either<Failures, bool>> restrictStorageSamples({
    required RestrictionType type,
    List<String> userIds,
    String reason,
  });

  /// Restrict / un-restrict transport car dispatch.
  Future<Either<Failures, bool>> restrictTransportCar({
    required bool status,
    String reason,
  });
}
