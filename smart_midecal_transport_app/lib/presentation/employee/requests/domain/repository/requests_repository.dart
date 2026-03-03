import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/request_sample_response_dm.dart';

abstract class RequestsRepository {
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(String id);
  Future<Either<Failures, RequestSampleResponseDm>> requestSample(
    String sampleId,
    String roomId,
  );
} 