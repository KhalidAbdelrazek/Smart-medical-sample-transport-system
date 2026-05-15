import 'package:easy_localization/easy_localization.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/data/data source/requests_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/data/models/add_to_car_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/data/models/dispatch_car_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/data/models/get_requests_response_dm.dart';

@Injectable(as: RequestsDataSource)
class RequestsDataSourceImpl implements RequestsDataSource {
  final ApiManager apiManager;

  RequestsDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, GetRequestsResponseDm>> getRequests() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
          path: ApiEndPoints.getRequests,
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        print(response.data.toString());
        GetRequestsResponseDm samplesResponseDm =
            GetRequestsResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(samplesResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: samplesResponseDm.message ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: 'errors.network_error'.tr()));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, AddToCarResponseDm>> addToCar(
    String sampleCode,
  ) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.addToCar,
          data: {"sample_code": sampleCode, "car_id": 3},
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        AddToCarResponseDm addToCarResponseDm = AddToCarResponseDm.fromJson(
          response.data,
        );
        print(response.data.toString());
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(addToCarResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: addToCarResponseDm.message ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: 'errors.network_error'.tr()));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, DispatchCarResponseDm>> dispatchCar() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.dispatchCar,
          data: {"car_id": 3},
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        DispatchCarResponseDm dispatchCarResponseDm =
            DispatchCarResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(dispatchCarResponseDm);
        }
        return Left(
          ServerError(errorMessage: dispatchCarResponseDm.errors.toString()),
        );
      } else {
        return Left(NetworkError(errorMessage: 'errors.network_error'.tr()));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  @override
  Future<Either<Failures, void>> removeFromCar(String requestId) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.deleteData(
          path: ApiEndPoints.removeFromCar(requestId),
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return const Right(null);
        }
        final errorMsg =
            (response.data is Map && response.data['message'] != null)
            ? response.data['message'].toString()
            : 'Failed to remove sample from car';
        return Left(ServerError(errorMessage: errorMsg));
      } else {
        return Left(NetworkError(errorMessage: 'errors.network_error'.tr()));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
