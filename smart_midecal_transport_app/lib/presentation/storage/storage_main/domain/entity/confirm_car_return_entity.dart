// {
//   "success": true,
//   "message": "Car return confirmed successfully",
//   "data": {
//     "car": {
//       "id": 3,
//       "car_number": "1",
//       "status": "IDLE"
//     },
//     "finalized_return_count": 0
//   },
//   "errors": null
// }


class ConfirmCarReturnEntity{
  final bool? success;
  final String? message;
  final DataEntity? data;
  final dynamic errors;

  ConfirmCarReturnEntity({this.success, this.message, this.data, this.errors});
}
class DataEntity {
  final CarEntity? car;
  final int? finalizedReturnCount;

  DataEntity({this.car, this.finalizedReturnCount});
}
class CarEntity {
  final int? id;
  final String? carNumber;
  final String? status;

  CarEntity({this.id, this.carNumber, this.status});
}
