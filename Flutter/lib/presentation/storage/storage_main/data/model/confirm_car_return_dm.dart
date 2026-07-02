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

import 'package:smart_midecal_transport_app/presentation/storage/storage_main/domain/entity/confirm_car_return_entity.dart';

class ConfirmCarReturnDm extends ConfirmCarReturnEntity {
  ConfirmCarReturnDm({super.success, super.message, super.data, super.errors});

  factory ConfirmCarReturnDm.fromJson(Map<String, dynamic> json) {
    return ConfirmCarReturnDm(
      success: json['success'],
      message: json['message'],
      data: DataDm.fromJson(json['data']),
      errors: json['errors'],
    );
  }
}

class DataDm extends DataEntity {
  DataDm({super.car, super.finalizedReturnCount});

  factory DataDm.fromJson(Map<String, dynamic> json) {
    return DataDm(
      car: CarDm.fromJson(json['car']),
      finalizedReturnCount: json['finalized_return_count'],
    );
  }
}

class CarDm extends CarEntity {
  CarDm({super.id, super.carNumber, super.status});

  factory CarDm.fromJson(Map<String, dynamic> json) {
    return CarDm(
      id: json['id'],
      carNumber: json['car_number'],
      status: json['status'],
    );
  }
}
