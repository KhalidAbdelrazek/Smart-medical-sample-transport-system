import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';

abstract class MyRequestsDataSource {
  

  // ── My Requests ──────────────────────────────────────────────────────────
  Future<Either<Failures, List<TransportMyRequestEntity>>> fetchMyRequests();
  Future<Either<Failures, bool>> cancelRequest(String requestId);
}