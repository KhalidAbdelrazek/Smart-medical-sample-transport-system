import 'package:either_dart/either.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/data/data source/requests_data_source.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/add_to_car_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/dispatch_car_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/repository/requests_repository.dart';

@Injectable(as: RequestsRepository)
class RequestsRepositoryImpl implements RequestsRepository {
  final RequestsDataSource requestsDataSource;

  RequestsRepositoryImpl({required this.requestsDataSource});

  @override
  Future<Either<Failures, GetRequestsResponseEntity>> getRequests() {
    return requestsDataSource.getRequests();
  }

  @override
  Future<Either<Failures, AddToCarResponseEntity>> addToCar(String sampleCode) {
    return requestsDataSource.addToCar(sampleCode);
  }

  @override
  Future<Either<Failures, DispatchCarResponseEntity>> dispatchCar() {
    return requestsDataSource.dispatchCar();
  }
}
