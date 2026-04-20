import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/entites/static_entity.dart';

abstract class StatisticsRepo {
  Future<Either<Failures, StatisticsEntity>> getStatistics();
}