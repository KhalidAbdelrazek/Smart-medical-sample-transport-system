import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

abstract class RestrictionsRepository {
  /// Fetch current restrictions status for all three domains.
  Future<Either<Failures, RestrictionsStatusEntity>> getRestrictionsStatus();

  /// Restrict / un-restrict doctor sample requests.
  /// [type] — NONE | GLOBAL | PARTIAL
  /// [doctorIds] — required only when type == PARTIAL
  Future<Either<Failures, bool>> restrictDoctorSamples({
    required RestrictionType type,
    List<String> doctorIds,
    String reason,
  });

  /// Restrict / un-restrict storage sample loading.
  /// [type] — NONE | GLOBAL | PARTIAL
  /// [employeeIds] — required only when type == PARTIAL
  Future<Either<Failures, bool>> restrictStorageSamples({
    required RestrictionType type,
    List<String> employeeIds,
    String reason,
  });

  /// Restrict / un-restrict transport car dispatch.
  Future<Either<Failures, bool>> restrictTransportCar({
    required bool status,
    String reason,
  });

  /// Fetch list of doctors for partial restriction selection.
  Future<Either<Failures, List<PersonEntity>>> getDoctors();

  /// Fetch list of storage employees for partial restriction selection.
  Future<Either<Failures, List<PersonEntity>>> getStorageEmployees();
}
