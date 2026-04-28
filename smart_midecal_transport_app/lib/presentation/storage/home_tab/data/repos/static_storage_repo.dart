import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/data/data_source/static_storage_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/domain/entities/static_storage_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/domain/repos/static_storage_repo.dart';

@Injectable(as: StorageStatisticsRepo)
class StorageStatisticsRepoImpl implements StorageStatisticsRepo {
  final StorageStatisticsRemoteDataSource remote;

  StorageStatisticsRepoImpl(this.remote);

  @override
  Future<Either<Failures, StorageStatisticsEntity>> getStatistics() {
    return remote.getStatistics();
  }
}