import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/data/data_source/static_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/entites/static_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/repos/static_repo.dart';



@Injectable(as: StatisticsRepo)
class StatisticsRepoImpl implements StatisticsRepo {
  final StatisticsRemoteDataSource remote;

  StatisticsRepoImpl(this.remote);

  @override
  Future<Either<Failures, StatisticsEntity>> getStatistics() {
    return remote.getStatistics();
  }
}