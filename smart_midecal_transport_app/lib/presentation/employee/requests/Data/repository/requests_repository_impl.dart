import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/bulk_request_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/data%20source/requests_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/transport_request_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/repository/requests_repository.dart';

@Injectable(as: RequestsRepository)
class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsDataSource requestsDataSource;

  RequestsRepositoryImpl({required this.requestsDataSource});

  @override
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(String id) {
    return requestsDataSource.getSampleById(id);
  }

  @override
  Future<Either<Failures, BulkRequestResponseDm>> requestBulkSamples(
    List<String> sampleCodes,
    String roomNumber,
  ) {
    return requestsDataSource.requestBulkSamples(sampleCodes, roomNumber);
  }

  // ── My Requests ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<TransportRequestEntity>>> getMyRequests() {
    return requestsDataSource.fetchMyRequests();
  }

  @override
  Future<Either<Failures, bool>> cancelRequest(String requestId) {
    return requestsDataSource.cancelRequest(requestId);
  }
}