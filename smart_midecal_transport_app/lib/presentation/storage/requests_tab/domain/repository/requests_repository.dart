import 'package:either_dart/either.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/add_to_car_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/dispatch_car_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';

abstract class RequestsRepository {
  Future<Either<Failures, GetRequestsResponseEntity>> getRequests();
  Future<Either<Failures, AddToCarResponseEntity>> addToCar(String sampleCode);
  Future<Either<Failures, DispatchCarResponseEntity>> dispatchCar();
} 