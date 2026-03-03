import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/request_sample_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/data%20source/requests_data_source.dart';

@Injectable(as: RequestsDataSource)
class RequestsDataSourceImpl implements RequestsDataSource {
  ApiManager apiManager;

  RequestsDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(
    String id,
  ) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
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
        GetSamplesResponseDm samplesResponseDm = GetSamplesResponseDm.fromJson(
          response.data,
        );
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

  @override
  Future<Either<Failures, RequestSampleResponseDm>> requestSample(
    String sampleId,
    String roomId,
  ) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.requestSample,
          data: {"sample_code": sampleId, "room_number": roomId},
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        print(response.data);

        RequestSampleResponseDm samplesResponseDm =
            RequestSampleResponseDm.fromJson(response.data);
        print(samplesResponseDm);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(samplesResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: samplesResponseDm.errors[0] ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: "Network Error"));
      }
    } catch (e) {
      // return Left(ServerError(errorMessage: e.toString()));
      throw Exception(e.toString());
    }
  }
}
