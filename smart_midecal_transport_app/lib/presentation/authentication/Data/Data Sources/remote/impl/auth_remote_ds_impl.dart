import 'package:easy_localization/easy_localization.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Data%20Sources/remote/auth_remote_ds.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_admin_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_admin_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_employee_rb_dm.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Data/Models/login_employee_response_dm.dart';

@Injectable(as: AuthRemoteDataSource)
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  ApiManager apiManager;
  AuthRemoteDataSourceImpl({required this.apiManager});

  @override
  Future<Either<Failures, LoginEmployeeResponseDm>> loginEmployee(
    LoginEmployeeRequestBodyDm loginEmployeeRequestBodyDm,
  ) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.employeeLogin,
          data: loginEmployeeRequestBodyDm.toJson(),
          options: Options(
            headers: {"Content-Type": "application/json"},
            validateStatus: (status) => true,
          ),
        );
        LoginEmployeeResponseDm loginEmployeeResponseDm =
            LoginEmployeeResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(loginEmployeeResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: loginEmployeeResponseDm.errors ?? "Server Error",
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
  Future<Either<Failures, LoginAdminResponseDm>> loginAdmin(
    LoginAdminRequestBodyDm loginAdminRequestBodyDm,
  ) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();
    try {
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.adminLogin,
          data: loginAdminRequestBodyDm.toJson(),
          options: Options(
            headers: {"Content-Type": "application/json"},
            validateStatus: (status) => true,
          ),
        );
        LoginAdminResponseDm loginAdminResponseDm =
            LoginAdminResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(loginAdminResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: loginAdminResponseDm.message ?? "Server Error",
          ),
        );
      } else {
        return Left(NetworkError(errorMessage: 'errors.network_error'.tr()));
      }
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
