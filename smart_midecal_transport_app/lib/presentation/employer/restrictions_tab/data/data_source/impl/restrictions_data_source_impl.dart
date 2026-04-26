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
      final errors = data['errors'];
      if (errors is Map<String, dynamic>) {
        final code = errors['code'] as String?;
        if (code == 'token_not_valid') return Left(TokenExpiredFailure());
        final detail = errors['detail'] as String?;
        return Left(ServerError(errorMessage: detail ?? 'Server error'));
      }
      final message = data['message'] as String?;
      return Left(ServerError(errorMessage: message ?? 'Server error'));
    }
    return Left(ServerError(errorMessage: 'Unexpected server error'));
  }

  // ─── GET restrictions/status/ ────────────────────────────────────────────

  @override
  Future<Either<Failures, RestrictionsStatusEntity>> getRestrictionsStatus() async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.getData(
        path: ApiEndPoints.restrictionsStatus,
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final model = RestrictionsStatusModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        return Right(model);
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
    List<String> doctorIds = const [],
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
          'doctor_ids': doctorIds,
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
    List<String> employeeIds = const [],
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
          'employee_ids': employeeIds,
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

  // ─── GET doctors list ────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<PersonEntity>>> getDoctors() async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.getData(
        path: ApiEndPoints.getDoctors,
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final rawList = response.data;
        List<dynamic> list;
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic>) {
          list = (rawList['results'] ?? rawList['data'] ?? []) as List<dynamic>;
        } else {
          list = [];
        }
        final doctors = list
            .map((e) => PersonModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(doctors);
      }
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }

  // ─── GET storage employees list ──────────────────────────────────────────

  @override
  Future<Either<Failures, List<PersonEntity>>> getStorageEmployees() async {
    if (!await _hasNetwork()) {
      return Left(NetworkError(errorMessage: 'No internet connection'));
    }
    try {
      final response = await apiManager.getData(
        path: ApiEndPoints.getStorageEmployees,
        options: _authOptions(),
      );
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        final rawList = response.data;
        List<dynamic> list;
        if (rawList is List) {
          list = rawList;
        } else if (rawList is Map<String, dynamic>) {
          list = (rawList['results'] ?? rawList['data'] ?? []) as List<dynamic>;
        } else {
          list = [];
        }
        final employees = list
            .map((e) => PersonModel.fromJson(e as Map<String, dynamic>))
            .toList();
        return Right(employees);
      }
      return _parseError(response);
    } catch (e) {
      return Left(ServerError(errorMessage: e.toString()));
    }
  }
}
