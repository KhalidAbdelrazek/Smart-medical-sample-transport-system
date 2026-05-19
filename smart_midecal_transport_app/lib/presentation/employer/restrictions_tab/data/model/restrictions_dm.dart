import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

class RestrictionsDm extends RestrictionsEntity {
  RestrictionsDm({super.success, super.message, super.data, super.errors});
  factory RestrictionsDm.fromJson(Map<String, dynamic> json) {
    return RestrictionsDm(
      success: json['success'],
      message: json['message'],
      data: json['data'] == null
          ? null
          : DoctorsOrStorageRestrictionsDm.fromJson(json['data']),
      errors: json['errors'],
    );
  }
}

class DoctorsOrStorageRestrictionsDm
    extends DoctorsOrStorageRestrictionsEntity {
  DoctorsOrStorageRestrictionsDm({
    super.storageSamples,
    super.doctorSamples,
    super.transportCar,
  });

  factory DoctorsOrStorageRestrictionsDm.fromJson(Map<String, dynamic> json) {
    return DoctorsOrStorageRestrictionsDm(
      storageSamples: json['storage_samples'] == null
          ? []
          : List<StorageSamplesEntity>.from(
              json['storage_samples']!.map((x) => StorageSamplesDm.fromJson(x)),
            ),
      doctorSamples: json['doctor_samples'] == null
          ? []
          : List<DoctorsSamplesEntity>.from(
              json['doctor_samples']!.map((x) => DoctorsSamplesDm.fromJson(x)),
            ),
      transportCar: json['transport_car'] == null
          ? null
          : TransportCarDm.fromJson(json['transport_car']),
    );
  }
}

class StorageSamplesDm extends StorageSamplesEntity {
  StorageSamplesDm({super.id, super.name, super.isRestricted});
  factory StorageSamplesDm.fromJson(Map<String, dynamic> json) {
    return StorageSamplesDm(
      id: json['id'],
      name: json['name'],
      isRestricted: json['is_restricted'],
    );
  }
}

class DoctorsSamplesDm extends DoctorsSamplesEntity {
  DoctorsSamplesDm({super.id, super.name, super.isRestricted});
  factory DoctorsSamplesDm.fromJson(Map<String, dynamic> json) {
    return DoctorsSamplesDm(
      id: json['id'],
      name: json['name'],
      isRestricted: json['is_restricted'],
    );
  }
}

class TransportCarDm extends TransportCarEntity {
  TransportCarDm({super.mode, super.isRestricted});
  factory TransportCarDm.fromJson(Map<String, dynamic> json) {
    return TransportCarDm(
      mode: json['mode'],
      isRestricted: json['is_restricted'],
    );
  }
}
