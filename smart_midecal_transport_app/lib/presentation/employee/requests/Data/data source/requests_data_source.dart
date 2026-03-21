import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/bulk_request_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';

abstract class RequestsDataSource {
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(
    String id,
  );
  Future<Either<Failures, BulkRequestResponseDm>> requestBulkSamples(
    List<String> sampleCodes,
    String roomNumber,
  );
}