import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';

abstract class AdminStatsDataSource {
  Future<Either<Failures, AdminStatsEntity>> getStatistics({required String selectedPeriod});
}