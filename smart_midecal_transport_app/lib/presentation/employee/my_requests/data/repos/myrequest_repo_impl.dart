

import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/data/data%20source/myrequest_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/repos/my_request_repo.dart';

@Injectable(as: MyRequestsRepository)
class MyRequestsRepositoryImpl implements MyRequestsRepository {
  final  MyRequestsDataSource myRequestsDataSource;
  
  MyRequestsRepositoryImpl({required this.myRequestsDataSource});

  

  // ── My Requests ───────────────────────────────────────────────────────────

  @override
  Future<Either<Failures, List<TransportMyRequestEntity>>> getMyRequests() {
    return myRequestsDataSource.fetchMyRequests();
  }

  @override
  Future<Either<Failures, bool>> cancelRequest(String requestId) {
    return myRequestsDataSource.cancelRequest(requestId);
  }

  @override
  Future<Either<Failures, bool>> requestReturn(String sampleId) {
    return myRequestsDataSource.requestReturn(sampleId);
  }
}
