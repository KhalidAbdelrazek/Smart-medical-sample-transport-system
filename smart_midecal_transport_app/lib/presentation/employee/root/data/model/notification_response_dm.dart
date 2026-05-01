// {
//   "success": true,
//   "message": "Found 1 delivery arrival(s)",
//   "data": [
//     {
//       "request_id": "df6383aa-19a2-48d8-8c00-4127e50e80b9",
//       "sample_id": "ead830d5-04e5-4ba1-ad6f-bf661c07ab2e",
//       "sample_name": "Khalid Abdelrazk",
//       "sample_code": "PT-0001",
//       "status": "ARRIVED_AT_DOCTOR_DELIVERY",
//       "room": "101"
//     }
//   ],
//   "errors": null
// }

import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';

class NotificationResponseDm extends NotificationResponseEntity {
  NotificationResponseDm({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory NotificationResponseDm.fromJson(Map<String, dynamic> json) =>
      NotificationResponseDm(
        success: json['success'],
        message: json['message'],
        data: (json['data'] as List<dynamic>?)
            ?.map((x) => NotificationDataDm.fromJson(x as Map<String, dynamic>))
            .toList(),
        errors: json['errors'],
      );
}

class NotificationDataDm extends NotificationDataEntity {
  NotificationDataDm({
    super.requestId,
    super.sampleId,
    super.sampleName,
    super.sampleCode,
    super.status,
    super.room,
  });

  factory NotificationDataDm.fromJson(Map<String, dynamic> json) =>
      NotificationDataDm(
        requestId: json['request_id'],
        sampleId: json['sample_id'],
        sampleName: json['sample_name'],
        sampleCode: json['sample_code'],
        status: json['status'],
        room: json['room'],
      );
}
