import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/data/data%20source/myrequest_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/data/models/transport_request_model.dart';


@Injectable(as: MyRequestsDataSource)
class MyRequestsDataSourceImpl implements MyRequestsDataSource {
  ApiManager apiManager;

  MyRequestsDataSourceImpl({required this.apiManager});
@override
  Future<Either<Failures, List<TransportMyRequestModel>>> fetchMyRequests() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final token = SharedPrefService.instance.getAccessToken();
      final response = await apiManager.getData(
        path: ApiEndPoints.getMyTransportRequests,
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

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        final dataList = (body?['data'] as List<dynamic>?)
                ?.map(
                  (e) => TransportMyRequestModel.fromJson(
                    e as Map<String, dynamic>?,
                  ),
                )
                .toList() ??
            [];
        return Right(dataList);
      }

      return Left(
        ServerError(errorMessage: body?['message']?.toString() ?? 'Server Error'),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ── Cancel Request → DELETE /api/transport/requests/{id}/cancel/ ──────────
  @override
  Future<Either<Failures, bool>> cancelRequest(String requestId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final token = SharedPrefService.instance.getAccessToken();
      final response = await apiManager.deleteData(
        path: ApiEndPoints.cancelTransportRequest(requestId),
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

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return Right(true);
      }

      // 404 – request not found / 403 – permission denied
      return Left(
        ServerError(
          errorMessage: body?['message']?.toString() ??
              body?['detail']?.toString() ??
              'Could not cancel request',
        ),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, bool>> requestReturn(String sampleId) async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final token = SharedPrefService.instance.getAccessToken();
      final response = await apiManager.postData(
        path: ApiEndPoints.requestReturn,
        data: {
          'sample_ids': [sampleId],
        },
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
        ServerError(
          errorMessage:
              body?['message']?.toString() ?? 'Could not request sample return',
        ),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}

