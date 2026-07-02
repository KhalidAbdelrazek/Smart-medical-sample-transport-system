// {
//     "success": true,
//     "message": "Search results fetched",
//     "data": [
//         {
//             "id": "4964bbaa-3dca-4140-822c-168c1e2e8a63",
//             "sample_code": "PT-0003",
//             "patient_name": "khalid abdelrazk2",
//             "status": "IN_STORAGE",
//             "is_in_storage": true
//         },
//         {
//             "id": "47b1ea9a-fb6b-427a-859b-7d7a87665e8c",
//             "sample_code": "PT-0002",
//             "patient_name": "khalid abdelrazk",
//             "status": "REQUESTED",
//             "is_in_storage": true
//         },
//         {
//             "id": "bb8e9fad-e572-4985-bf72-6d11d28c1394",
//             "sample_code": "PT-0001",
//             "patient_name": "Test Patient",
//             "status": "OUT_FOR_DELIVERY",
//             "is_in_storage": false
//         }
//     ],
//     "errors": null
// }

class SamplesResponseEntity {
  final bool? success;
  final String? message;
  final List<SampleEntity>? data;
  final dynamic errors;

  SamplesResponseEntity({this.success, this.message, this.data, this.errors});

  // from json
  factory SamplesResponseEntity.fromJson(Map<String, dynamic> json) {
    return SamplesResponseEntity(
      success: json['success'] as bool,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => SampleEntity.fromJson(e as Map<String, dynamic>))
          .toList(),
      errors: json['errors'],
    );
  }
}

class SampleEntity {
  final String? id;
  final String? sampleCode;
  final String? patientName;
  final String? status;
  final bool? isInStorage;

  SampleEntity({
    this.id,
    this.sampleCode,
    this.patientName,
    this.status,
    this.isInStorage,
  });

  // from json
  factory SampleEntity.fromJson(Map<String, dynamic> json) {
    return SampleEntity(
      id: json['id'] as String,
      sampleCode: json['sample_code'] as String,
      patientName: json['patient_name'] as String,
      status: json['status'] as String,
      isInStorage: json['is_in_storage'] as bool,
    );
  }
}
