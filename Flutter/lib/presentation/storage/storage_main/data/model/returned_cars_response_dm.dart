// {
//   "success": true,
//   "message": "Found 1 returned car(s) awaiting confirmation",
//   "data": {
//     "returned_cars": [
//       {
//         "id": 3,
//         "car_number": "1",
//         "status": "DISPATCHED",
//         "arrived_at_storage": "2026-05-09T19:09:09+03:00",
//         "capacity": 10,
//         "created_at": "2026-04-29T01:31:12.945376+03:00",
//         "car_id": 3
//       }
//     ]
//   },
//   "errors": null
// }
import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/returned_cars_response_entity.dart';

class ReturnedCarsResponseDm extends ReturnedCarsResponseEntity {
  ReturnedCarsResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory ReturnedCarsResponseDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ReturnedCarsResponseDm();
    return ReturnedCarsResponseDm(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null
          ? ReturnedCarsDataDm.fromJson(json['data'])
          : null,
      errors: json['errors'],
    );
  }
}

class ReturnedCarsDataDm extends ReturnedCarsDataEntity {
  ReturnedCarsDataDm({super.returnedCars});
  factory ReturnedCarsDataDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ReturnedCarsDataDm();
    return ReturnedCarsDataDm(
      returnedCars: json['returned_cars'] != null
          ? (json['returned_cars'] as List)
                .map((e) => ReturnedCarDm.fromJson(e))
                .toList()
          : null,
    );
  }
}

class ReturnedCarDm extends ReturnedCarEntity {
  ReturnedCarDm({
    super.id,
    super.carNumber,
    super.status,
    super.arrivedAtStorage,
    super.capacity,
    super.createdAt,
    super.carId,
  });
  factory ReturnedCarDm.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ReturnedCarDm();
    return ReturnedCarDm(
      id: json['id'],
      carNumber: json['car_number'],
      status: json['status'],
      arrivedAtStorage: json['arrived_at_storage'],
      capacity: json['capacity'],
      createdAt: json['created_at'],
      carId: json['car_id'],
    );
  }
}
