import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/data/data_source/static_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/entites/static_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/repos/static_repo.dart';

@Injectable(as: EmploeeStatisticsRepo)
class EmployeeStatisticsRepoImpl implements EmploeeStatisticsRepo {
  final EmploeeStatisticsRemoteDataSource remote;

  EmployeeStatisticsRepoImpl(this.remote);

  @override
  Future<Either<Failures, EmploeeStatisticsEntity>> getStatistics() {
    return remote.getStatistics();
  }
}
