import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/data/data_source/restrictions_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/repos/restrictions_repository.dart';

@Injectable(as: RestrictionsRepository)
class RestrictionsRepositoryImpl implements RestrictionsRepository {
  final RestrictionsDataSource remote;

  RestrictionsRepositoryImpl(this.remote);

  @override
  Future<Either<Failures, RestrictionsEntity>> getRestrictionsStatus({
    required String type,
  }) =>
      remote.getRestrictionsStatus(type: type);

  @override
  Future<Either<Failures, bool>> restrictDoctorSamples({
    required RestrictionType type,
    List<String> userIds = const [],
    String reason = '',
  }) =>
      remote.restrictDoctorSamples(
        type: type,
        userIds: userIds,
        reason: reason,
      );

  @override
  Future<Either<Failures, bool>> restrictStorageSamples({
    required RestrictionType type,
    List<String> userIds = const [],
    String reason = '',
  }) =>
      remote.restrictStorageSamples(
        type: type,
        userIds: userIds,
        reason: reason,
      );

  @override
  Future<Either<Failures, bool>> restrictTransportCar({
    required bool status,
    String reason = '',
  }) =>
      remote.restrictTransportCar(status: status, reason: reason);
}
