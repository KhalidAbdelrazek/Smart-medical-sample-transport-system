import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/domain/entities/static_storage_entity.dart';

abstract class StorageStatisticsRepo {
  Future<Either<Failures, StorageStatisticsEntity>> getStatistics();
}