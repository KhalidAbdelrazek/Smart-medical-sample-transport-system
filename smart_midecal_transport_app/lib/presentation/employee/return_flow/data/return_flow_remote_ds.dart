import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/domain/entities/return_status_entity.dart';

class ReturnFlowRemoteDataSource {
  final ApiManager apiManager;

  ReturnFlowRemoteDataSource({required this.apiManager});

  Future<Either<Failures, List<ReturnStatusEntity>>> fetchReturnStatus() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }

    try {
      final token = SharedPrefService.instance.getAccessToken();
      final response = await apiManager.getData(
        path: ApiEndPoints.returnStatus,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 401) {
        return Left(TokenExpiredFailure());
      }

      final body = response.data as Map<String, dynamic>?;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final rows = (body?['data'] as List<dynamic>? ?? [])
            .map((row) => ReturnStatusEntity.fromJson(row as Map<String, dynamic>))
            .toList();
        return Right(rows);
      }

      return Left(
        ServerError(errorMessage: body?['message']?.toString() ?? 'Server Error'),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  Future<Either<Failures, bool>> confirmReturn(String batchId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }

    try {
      final token = SharedPrefService.instance.getAccessToken();
      final response = await apiManager.postData(
        path: ApiEndPoints.confirmReturn,
        data: {'batch_id': batchId},
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 401) {
        return Left(TokenExpiredFailure());
      }

      final body = response.data as Map<String, dynamic>?;
      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        return const Right(true);
      }

      return Left(
        ServerError(errorMessage: body?['message']?.toString() ?? 'Could not confirm return'),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
