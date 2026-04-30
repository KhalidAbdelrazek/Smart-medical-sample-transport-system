import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/data/data_source/static_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/data/model/static_model.dart';

@Injectable(as: EmploeeStatisticsRemoteDataSource)
class EmploeeStatisticsRemoteDataSourceImpl
    implements EmploeeStatisticsRemoteDataSource {
  final ApiManager apiManager;

  EmploeeStatisticsRemoteDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, EmploeeStatisticsModel>> getStatistics() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
         path: ApiEndPoints.statisticsDashboard,
          queryParameters: {
            "period": "month",
          },
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );

        EmploeeStatisticsModel model =
            EmploeeStatisticsModel.fromJson(response.data);

        if (response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return Right(model);
        }

        return Left(
          ServerError(
            errorMessage: response.data["message"] ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: "Network Error"));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}