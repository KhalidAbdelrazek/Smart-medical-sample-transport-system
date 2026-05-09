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

class ReturnedCarsResponseEntity {
  final bool? success;
  final String? message;
  final ReturnedCarsDataEntity? data;
  final dynamic errors;

  ReturnedCarsResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}

class ReturnedCarsDataEntity {
  final List<ReturnedCarEntity>? returnedCars;
  ReturnedCarsDataEntity({this.returnedCars});
}

class ReturnedCarEntity {
  final int? id;
  final String? carNumber;
  final String? status;
  final String? arrivedAtStorage;
  final int? capacity;
  final String? createdAt;
  final int? carId;
  ReturnedCarEntity({this.id, this.carNumber, this.status, this.arrivedAtStorage, this.capacity, this.createdAt, this.carId});
}
