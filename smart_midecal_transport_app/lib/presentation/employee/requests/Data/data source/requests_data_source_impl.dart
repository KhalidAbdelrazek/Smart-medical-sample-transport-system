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
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/data%20source/requests_data_source.dart';

@Injectable(as: RequestsDataSource)
class RequestsDataSourceImpl implements RequestsDataSource {
  ApiManager apiManager;

  RequestsDataSourceImpl({required this.apiManager});

  // ----------------------------------------------------------------
  // Get sample(s) by patient ID / code
  // ----------------------------------------------------------------
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

  // ----------------------------------------------------------------
  // Bulk sample request  → POST /api/samples/request-bulk/
  // ----------------------------------------------------------------
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

      // ── Case A: Token expired / invalid (401) ──────────────────
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

      // ── Parse standard response body ───────────────────────────
      final BulkRequestResponseDm bulkResponse =
          BulkRequestResponseDm.fromJson(response.data as Map<String, dynamic>);

      // Check embedded token-not-valid in a 200-ish response (some APIs do this)
      if (bulkResponse.isTokenExpired) {
        return Left(TokenExpiredFailure());
      }

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return Right(bulkResponse);
      }

      // ── Case C: Generic server error ───────────────────────────
      return Left(
        ServerError(errorMessage: bulkResponse.message ?? "Server Error"),
      );
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
