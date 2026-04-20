import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/data/model/static_model.dart';

abstract class StatisticsRemoteDataSource {
  Future<Either<Failures, StatisticsModel>> getStatistics();
}