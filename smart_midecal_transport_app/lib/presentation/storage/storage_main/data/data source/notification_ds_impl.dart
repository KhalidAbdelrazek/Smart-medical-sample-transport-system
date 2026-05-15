import 'package:easy_localization/easy_localization.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/data%20source/notification_ds.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/model/confirm_car_return_dm.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/data/model/returned_cars_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/confirm_car_return_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';

class NotificationDsImpl extends NotificationDs{
  final ApiManager apiManager;
  NotificationDsImpl({required this.apiManager});
  
  @override
  Future<Either<Failures, ReturnedCarsResponseDm>> getReturnedCars() async{
   
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();

    try {
      final String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
          path: ApiEndPoints.getCar,
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
        ReturnedCarsResponseDm returnedCarsResponseDm = ReturnedCarsResponseDm.fromJson(response.data);

        // 1. Check for specific Token Expiration / Invalid Token
        if (returnedCarsResponseDm.errors?.code == "token_not_valid") {
          return Left(
            ServerError(errorMessage: 'extra.session_expired'.tr()),
          );
        }

        // 2. Check for General Success (2xx status codes)
        if (response.statusCode! >= 200 &&
            response.statusCode! < 300 &&
            returnedCarsResponseDm.success==true) {
          return Right(returnedCarsResponseDm);
        }

        // 3. Handle other Server Errors
        return Left(
          ServerError(errorMessage: returnedCarsResponseDm.message?.toString() ?? "Server Error"),
        );
      } else {
        return Left(NetworkError(errorMessage: 'extra.no_internet_lower'.tr()));
      }
    } catch (e) {
      return Left(
        ServerError(errorMessage: "Unexpected Error: ${e.toString()}"),
      );
    }
    
  }

  @override
  Future<Either<Failures, ConfirmCarReturnDm>> confirmReturnedCar(int carId) async {
    final List<ConnectivityResult> connectivityResult = await Connectivity()
        .checkConnectivity();

    try {
      final String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.confirmReturnedCar,
          data: {"car_id": carId},
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
        ConfirmCarReturnDm confirmCarReturnDm = ConfirmCarReturnDm.fromJson(response.data);

        // 1. Check for specific Token Expiration / Invalid Token
        if (confirmCarReturnDm.errors?.code == "token_not_valid") {
          return Left(
            ServerError(errorMessage: 'extra.session_expired'.tr()),
          );
        }

        // 2. Check for General Success (2xx status codes)
        if (response.statusCode! >= 200 &&
            response.statusCode! < 300) {
          return Right(confirmCarReturnDm);
        }

        // 3. Handle other Server Errors
        return Left(
          ServerError(errorMessage: confirmCarReturnDm.message?.toString() ?? "Server Error"),
        );
      } else {
        return Left(NetworkError(errorMessage: 'extra.no_internet_lower'.tr()));
      }
    } catch (e) {
      return Left(
        ServerError(errorMessage: "Unexpected Error: ${e.toString()}"),
      );
    }
  }
}