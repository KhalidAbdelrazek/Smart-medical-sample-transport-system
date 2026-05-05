// {
//   "success": true,
//   "message": "Found 1 delivery arrival(s)",
//   "data": {
//     "arrivals": [
//       {
//         "request_id": "211d3fc4-95bb-4163-b28b-924495c5628e",
//         "sample_id": "8fafbbd7-72e1-462e-a0ed-e99e87b88b4f",
//         "sample_name": "Nader Abou-Elfadl",
//         "sample_code": "PT-0004",
//         "status": "ARRIVED_AT_DOCTOR_DELIVERY",
//         "room": "101"
//       }
//     ],
//     "return_offer": true,
//     "returnable_samples": [
//       {
//         "sample_id": "052d4ceb-5434-4ea3-8dac-7bedfabe2945",
//         "sample_code": "PT-0002",
//         "patient_name": "Mohammed Ashraf"
//       },
//       {
//         "sample_id": "ead830d5-04e5-4ba1-ad6f-bf661c07ab2e",
//         "sample_code": "PT-0001",
//         "patient_name": "Khalid Abdelrazk"
//       }
//     ]
//   },
//   "errors": null
// }




class NotificationResponseEntity {
  final bool? success;
  final String? message;
  final NotificationDataEntity? data;
  final dynamic errors;

  NotificationResponseEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}


class NotificationDataEntity {
  final List<NotificationArrivalsEntity>? arrivals;
  final bool? returnOffer;
  final List<ReturnableSamplesEntity>? returnableSamples;

  NotificationDataEntity({
    this.arrivals,
    this.returnOffer,
    this.returnableSamples,
  });
}

class NotificationArrivalsEntity {
  final String? requestId;
  final String? sampleId;
  final String? sampleName;
  final String? sampleCode;
  final String? status;
  final String? room;

  NotificationArrivalsEntity({
    this.requestId,
    this.sampleId,
    this.sampleName,
    this.sampleCode,
    this.status,
    this.room,
  });
}

class ReturnableSamplesEntity {
  final String? sampleId;
  final String? sampleCode;
  final String? patientName;

  ReturnableSamplesEntity({
    this.sampleId,
    this.sampleCode,
    this.patientName,
  });
}