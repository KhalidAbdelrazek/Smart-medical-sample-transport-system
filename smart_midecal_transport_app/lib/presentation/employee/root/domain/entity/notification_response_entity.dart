
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

class NotificationResponseEntity {
  final bool? success;
  final String? message;
  final List<NotificationDataEntity>? data;
  final dynamic errors;

  NotificationResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}

class NotificationDataEntity {
  final String? requestId;
  final String? sampleId;
  final String? sampleName;
  final String? sampleCode;
  final String? status;
  final String? room;

  NotificationDataEntity({
    this.requestId,
    this.sampleId,
    this.sampleName,
    this.sampleCode,
    this.status,
    this.room,
  });
}
