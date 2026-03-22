import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Data%20Sources/profile_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/profile_tab/Data/Models/get_profle_dm.dart';

@Injectable(as: ProfileDataSource)
class ProfileDataSourceImpl implements ProfileDataSource {
  ApiManager apiManager;
  ProfileDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, GetProfileDm>> getProfile() async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();

    try {
      final String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
          path: ApiEndPoints.getProfile,
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        print("response.data: ${response.data}");

        // Map the entire response (success, message, data, errors)
        GetProfileDm getProfileDm = GetProfileDm.fromJson(response.data);

        // 1. Check for specific Token Expiration / Invalid Token
        if (getProfileDm.errors?.code == "token_not_valid") {
          return Left(
            ServerError(errorMessage: "Session expired. Please login again."),
          );
        }

        // 2. Check for General Success (2xx status codes)
        if (response.statusCode! >= 200 &&
            response.statusCode! < 300 &&
            getProfileDm.success) {
          return Right(getProfileDm);
        }

        // 3. Handle other Server Errors
        return Left(
          ServerError(errorMessage: getProfileDm.message ?? "Server Error"),
        );
      } else {
        return Left(NetworkError(errorMessage: "No Internet Connection"));
      }
    } catch (e) {
      return Left(
        ServerError(errorMessage: "Unexpected Error: ${e.toString()}"),
      );
    }
  }
}
