enum RestrictionType {
  allUnrestrict,
  globalRestrict,
  partialRestrict,
  partialUnrestrict,
}

extension RestrictionTypeX on RestrictionType {
  String get value {
    switch (this) {
      case RestrictionType.allUnrestrict:
        return 'ALL_UNRESTRICT';
      case RestrictionType.globalRestrict:
        return 'GLOBAL_RESTRICT';
      case RestrictionType.partialRestrict:
        return 'PARTIAL_RESTRICT';
      case RestrictionType.partialUnrestrict:
        return 'PARTIAL_UNRESTRICT';
    }
  }

  static RestrictionType fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'GLOBAL_RESTRICT':
        return RestrictionType.globalRestrict;
      case 'PARTIAL_RESTRICT':
        return RestrictionType.partialRestrict;
      case 'PARTIAL_UNRESTRICT':
        return RestrictionType.partialUnrestrict;
      default:
        return RestrictionType.allUnrestrict;
    }
  }
}

// {
//     "success": true,
//     "message": "Current system restrictions fetched successfully.",
//     "data": {
//         "storage_samples": [
//             {
//                 "id": "f5f8b6fe-2121-4376-b266-422ad46778f9",
//                 "name": "Storage Employee One",
//                 "is_restricted": false
//             },
//             {
//                 "id": "f50b7a42-fb99-4354-ae71-f5d61ba7f6e4",
//                 "name": "Storage Employee Two",
//                 "is_restricted": false
//             }
//         ]
//     },
//     "errors": null
// }


class RestrictionsEntity {
  final bool? success;
  final String? message;
  final DoctorsOrStorageRestrictionsEntity? data;
  final String? errors;

  RestrictionsEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}

class DoctorsOrStorageRestrictionsEntity {
  final List<StorageSamplesEntity>? storageSamples;
  final List<DoctorsSamplesEntity>? doctorSamples;
  final TransportCarEntity? transportCar;
  DoctorsOrStorageRestrictionsEntity({
    this.storageSamples,
    this.doctorSamples,
    this.transportCar,
  });
}

class StorageSamplesEntity {
  final String? id;
  final String? name;
  final bool? isRestricted;

  StorageSamplesEntity({this.id, this.name, this.isRestricted});
}
class DoctorsSamplesEntity{
  final String? id;
  final String? name;
  final bool? isRestricted;

  DoctorsSamplesEntity({this.id, this.name, this.isRestricted});
} 

class TransportCarEntity{
  final String? mode;
  final bool? isRestricted;
  TransportCarEntity({this.mode, this.isRestricted});
}