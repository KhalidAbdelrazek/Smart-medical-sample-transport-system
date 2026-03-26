import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/bulk_request_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/transport_request_model.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/data%20source/requests_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/transport_request_entity.dart';

@Injectable(as: RequestsDataSource)
class RequestsDataSourceImpl implements RequestsDataSource {
  ApiManager apiManager;

  RequestsDataSourceImpl({required this.apiManager});

  // ── Get sample(s) by patient ID / code ───────────────────────────────────
  @override
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(
    String id,
  ) async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
          path: "${ApiEndPoints.getSampleById}$id/",
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        GetSamplesResponseDm samplesResponseDm =
            GetSamplesResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(samplesResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: samplesResponseDm.message ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: "Network Error"));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ── Bulk sample request → POST /api/samples/request-bulk/ ────────────────
  @override
  Future<Either<Failures, BulkRequestResponseDm>> requestBulkSamples(
    List<String> sampleCodes,
    String roomNumber,
  ) async {
    final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult.contains(ConnectivityResult.none)) {
      return Left(NetworkError(errorMessage: "No internet connection"));
    }

    try {
      final String? token = SharedPrefService.instance.getAccessToken();

      final response = await apiManager.postData(
        path: ApiEndPoints.requestBulkSample,
        data: {
          "sample_codes": sampleCodes,
          "room_number": roomNumber,
        },
        options: Options(
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          validateStatus: (status) => true,
        ),
      );

      // ── Case A: Token expired / invalid (401) ─────────────────────────────
      if (response.statusCode == 401) {
        final body = response.data;
        if (body is Map && body['errors'] != null) {
          final errCode = body['errors']['code'];
          if (errCode == 'token_not_valid') {
            return Left(TokenExpiredFailure());
          }
        }
        return Left(TokenExpiredFailure());
      }

      // ── Parse standard response body ──────────────────────────────────────
      final BulkRequestResponseDm bulkResponse =
          BulkRequestResponseDm.fromJson(response.data as Map<String, dynamic>);

      if (bulkResponse.isTokenExpired) {
        return Left(TokenExpiredFailure());
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return Right(bulkResponse);
      }

      return Left(
        ServerError(errorMessage: bulkResponse.message ?? "Server Error"),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ── My Requests → GET /api/transport/my-requests/ ────────────────────────
  @override
  Future<Either<Failures, List<TransportRequestEntity>>> fetchMyRequests() async {
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
                  (e) => TransportRequestModel.fromJson(
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
}
