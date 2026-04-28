// {
//     "success": true,
//     "message": "Current system restrictions fetched successfully.",
//     "data": {
//         "doctor_samples": {
//             "mode": "NONE",
//             "reason": "",
//             "updated_at": "2026-04-26T17:34:44.856412Z",
//             "restricted_users": []
//         },
//         "storage_samples": {
//             "mode": "NONE",
//             "reason": "",
//             "updated_at": "2026-04-25T17:59:59.894456Z",
//             "restricted_users": []
//         },
//         "transport_car": {
//             "mode": "NONE",
//             "reason": "",
//             "updated_at": "2026-04-25T17:59:59.895014Z",
//             "restricted_users": []
//         }
//     },
//     "errors": null
// }

// class RestrictionsStatusEntity {
//   final bool? success;
//   final String? message;
//   final RestrictionsDataEntity? data;
//   final dynamic errors;

//   RestrictionsStatusEntity({
//     this.success,
//     this.message,
//     this.data,
//     this.errors,
//   });
// }

// class RestrictionsDataEntity {
//   final DoctorRestrictionEntity? doctorRestriction;
//   final StorageRestrictionEntity? storageRestriction;
//   final CarRestrictionEntity? carRestriction;

//   RestrictionsDataEntity({
//     this.doctorRestriction,
//     this.storageRestriction,
//     this.carRestriction,
//   });
// }

// class DoctorRestrictionEntity {
//   final String? restrictionType;
//   final List<String>? doctorIds;
//   final String? reason;

//   DoctorRestrictionEntity({
//     this.restrictionType,
//     this.doctorIds,
//     this.reason,
//   });
// }

// class StorageRestrictionEntity {
//   final String? restrictionType;
//   final List<String>? employeeIds;
//   final String? reason;

//   StorageRestrictionEntity({
//     this.restrictionType,
//     this.employeeIds,
//     this.reason,
//   });
// }

// class CarRestrictionEntity {
//   final   bool? status;
//   final String? reason;

//   CarRestrictionEntity({this.status, this.reason});
// }