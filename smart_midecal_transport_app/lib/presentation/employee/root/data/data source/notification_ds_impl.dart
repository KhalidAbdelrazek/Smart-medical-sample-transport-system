import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/data/model/notification_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/root/data/data source/notification_ds.dart';

@Injectable(as: NotificationDataSource)
class NotificationDsImpl implements NotificationDataSource {
  final ApiManager apiManager;
  NotificationDsImpl({required this.apiManager});

  @override
  Future<Either<Failures, NotificationResponseDm>> getNotifications() async{
final List<ConnectivityResult> connectivityResult =
        await Connectivity().checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.getData(
          path: ApiEndPoints.notifications,
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        NotificationResponseDm notificationResponseDm =
            NotificationResponseDm.fromJson(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right(notificationResponseDm);
        }
        return Left(
          ServerError(
            errorMessage: notificationResponseDm.errors.toString(),
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
  Future<Either<Failures, String?>> confirmDelivery({required String requestId}) async{
    final List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.confirmDelivery(requestId),
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        print(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right("Delivery confirmed successfully");
        }
        return Left(
          ServerError(
            errorMessage: response.data["message"]?.toString() ?? "Unreliable Error",
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
  Future<Either<Failures, String?>> rejectDelivery({required String requestId}) async{
    final List<ConnectivityResult> connectivityResult =
    await Connectivity().checkConnectivity();
    try {
      String? token = SharedPrefService.instance.getAccessToken();
      if (!connectivityResult.contains(ConnectivityResult.none)) {
        var response = await apiManager.postData(
          path: ApiEndPoints.rejectDelivery(requestId),
          options: Options(
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            validateStatus: (status) => true,
          ),
        );
        print(response.data);
        if (response.statusCode! >= 200 && response.statusCode! < 300) {
          return Right("Delivery rejected successfully");
        }
        return Left(
          ServerError(
            errorMessage: response.data["message"]?.toString() ?? "Unreliable Error",
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