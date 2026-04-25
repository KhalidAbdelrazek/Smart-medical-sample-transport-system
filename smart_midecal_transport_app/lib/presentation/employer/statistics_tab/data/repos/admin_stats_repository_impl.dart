import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/data/data_source/admin_stats_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/repos/admin_stats_repository.dart';

@Injectable(as: AdminStatsRepository)
class AdminStatsRepositoryImpl implements AdminStatsRepository {
  final AdminStatsDataSource remote;

  AdminStatsRepositoryImpl(this.remote);

  @override
  Future<Either<Failures, AdminStatsEntity>> getStatistics({required String selectedPeriod}) {
    return remote.getStatistics(selectedPeriod: selectedPeriod);
  }
}