import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/my_requests/domain/entities/tranport_req_entities.dart';

abstract class MyRequestsRepository {
  // ── My Requests ──────────────────────────────────────────────────────────
  Future<Either<Failures, List<TransportMyRequestEntity>>> getMyRequests();
  Future<Either<Failures, bool>> cancelRequest(String requestId);
}
