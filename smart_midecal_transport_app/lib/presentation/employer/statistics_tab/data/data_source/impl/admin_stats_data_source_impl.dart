import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/data/data_source/admin_stats_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/data/model/admin_stats_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';

@Injectable(as: AdminStatsDataSource)
class AdminStatsDataSourceImpl implements AdminStatsDataSource {
  final ApiManager apiManager;

  AdminStatsDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, AdminStatsEntity>> getStatistics({
    required String selectedPeriod,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }

    try {
      final String? token = SharedPrefService.instance.getAccessToken();

      final response = await apiManager.getData(
        path: ApiEndPoints.statisticsDashboard,
        queryParameters: {'period': selectedPeriod},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      final statusCode = response.statusCode ?? 0;

      if (statusCode >= 200 && statusCode < 300) {
        final model = AdminStatsModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Right(model);
      }

      // ── Error response handling ──────────────────────────────────────────
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          final code = errors['code'] as String?;
          if (code == 'token_not_valid') {
            return Left(TokenExpiredFailure());
          }
          final detail = errors['detail'] as String?;
          return Left(ServerError(errorMessage: detail ?? 'Server error'));
        }
        final message = responseData['message'] as String?;
        return Left(ServerError(errorMessage: message ?? 'Server error'));
      }

      return Left(ServerError(errorMessage: 'Unexpected server error'));
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}