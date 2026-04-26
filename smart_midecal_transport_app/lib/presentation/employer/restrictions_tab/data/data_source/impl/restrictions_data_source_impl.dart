import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_endpoints.dart';
import 'package:smart_midecal_transport_app/core/api%20manager/api_manager.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/data/data_source/restrictions_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/data/model/restrictions_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

@Injectable(as: RestrictionsDataSource)
class RestrictionsDataSourceImpl implements RestrictionsDataSource {
  final ApiManager apiManager;

  RestrictionsDataSourceImpl({required this.apiManager});

  // ─── Shared helpers ──────────────────────────────────────────────────────

  Future<bool> _hasNetwork() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Options _authOptions() {
    final token = SharedPrefService.instance.getAccessToken();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      validateStatus: (status) => true,
    );
  }

  Either<Failures, T> _parseError<T>(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final message = data['message'] as String?;
      return Left(ServerError(errorMessage: message ?? 'Server error'));
    }
    return Left(ServerError(errorMessage: 'Unexpected server error'));
  }

  // ─── GET restrictions/status/ ────────────────────────────────────────────

  @override
  Future<Either<Failures, List<PersonEntity>>> getRestrictionsStatus({
    required String type,
  }) async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.getData(
        path: '${ApiEndPoints.restrictionsStatus}?type=$type',
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['data'] != null) {
          return Right(PersonModel.fromJsonList(data['data']));
        }
        return const Right([]);
      }
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ─── POST restrict-doctor-samples/ ──────────────────────────────────────

  @override
  Future<Either<Failures, bool>> restrictDoctorSamples({
    required RestrictionType type,
    List<String> userIds = const [],
    String reason = '',
  }) async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.postData(
        path: ApiEndPoints.restrictDoctorSamples,
        data: {
          'restriction_type': type.value,
          'user_ids': userIds,
          'reason': reason,
        },
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return const Right(true);
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ─── POST restrict-storage-samples/ ─────────────────────────────────────

  @override
  Future<Either<Failures, bool>> restrictStorageSamples({
    required RestrictionType type,
    List<String> userIds = const [],
    String reason = '',
  }) async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.postData(
        path: ApiEndPoints.restrictStorageSamples,
        data: {
          'restriction_type': type.value,
          'user_ids': userIds,
          'reason': reason,
        },
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return const Right(true);
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ─── POST restrict-transport-car/ ───────────────────────────────────────

  @override
  Future<Either<Failures, bool>> restrictTransportCar({
    required bool status,
    String reason = '',
  }) async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.postData(
        path: ApiEndPoints.restrictTransportCar,
        data: {'status': status, 'reason': reason},
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return const Right(true);
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
