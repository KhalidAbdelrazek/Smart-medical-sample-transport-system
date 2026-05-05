
import 'package:smart_midecal_transport_app/presentation/employee/root/domain/entity/notification_response_entity.dart';



class NotificationResponseDm extends NotificationResponseEntity{
  NotificationResponseDm({super.success, super.message, super.data, super.errors});

  factory NotificationResponseDm.fromJson(Map<String, dynamic> json) {
    return NotificationResponseDm(
      success: json['success'],
      message: json['message'],
      data: json['data'] != null ? NotificationDataData.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }
}


class NotificationDataData extends NotificationDataEntity{

  NotificationDataData({super.arrivals, super.returnOffer, super.returnableSamples});
  factory NotificationDataData.fromJson(Map<String, dynamic> json) {
    return NotificationDataData(
arrivals: json['arrivals'] != null
    ? (json['arrivals'] as List)
        .map((e) => NotificationArrivalsData.fromJson(e))
        .toList()
    : [],
      returnOffer: json['return_offer'],
returnableSamples: json['returnable_samples'] != null
    ? (json['returnable_samples'] as List)
        .map((e) => ReturnableSamplesData.fromJson(e))
        .toList()
    : [],    );
  }
}

class NotificationArrivalsData extends NotificationArrivalsEntity{
  NotificationArrivalsData({super.requestId, super.sampleId, super.sampleName, super.sampleCode, super.status, super.room});
  factory NotificationArrivalsData.fromJson(Map<String, dynamic> json) {
    return NotificationArrivalsData(
      requestId: json['request_id'],
      sampleId: json['sample_id'],
      sampleName: json['sample_name'],
      sampleCode: json['sample_code'],
      status: json['status'],
      room: json['room'],
    );
  }
}

class ReturnableSamplesData extends ReturnableSamplesEntity{

  ReturnableSamplesData({super.sampleId, super.sampleCode, super.patientName});
  factory ReturnableSamplesData.fromJson(Map<String, dynamic> json) {
    return ReturnableSamplesData(
      sampleId: json['sample_id'],
      sampleCode: json['sample_code'],
      patientName: json['patient_name'],
    );
  }
}