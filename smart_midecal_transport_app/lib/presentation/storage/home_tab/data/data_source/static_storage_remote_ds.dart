import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/data/model/storage_model.dart';

abstract class StorageStatisticsRemoteDataSource {
  Future<Either<Failures, StorageStatisticsModel>> getStatistics();
}