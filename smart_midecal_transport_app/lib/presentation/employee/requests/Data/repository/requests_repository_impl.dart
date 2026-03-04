import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/get_samples_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/Models/request_sample_response_dm.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/Data/data%20source/requests_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/repository/requests_repository.dart';

@Injectable(as: RequestsRepository)
class RequestsRepositoryImpl implements RequestsRepository {
  RequestsDataSource requestsDataSource;
  RequestsRepositoryImpl({required this.requestsDataSource});

  @override
  Future<Either<Failures, GetSamplesResponseDm>> getSampleById(String id) {
    return requestsDataSource.getSampleById(id);
  }

  @override
  Future<Either<Failures, RequestSampleResponseDm>> requestSample(
    String sampleId,
    String roomId,
  ) {
    return requestsDataSource.requestSample(sampleId, roomId);
  }
}