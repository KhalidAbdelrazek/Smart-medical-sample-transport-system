import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

// ─── Restrictions Status Response ─────────────────────────────────────────

class RestrictionsStatusModel extends RestrictionsStatusEntity {
  RestrictionsStatusModel({
    super.success,
    super.message,
    super.data,
    super.errors,
  });

  factory RestrictionsStatusModel.fromJson(Map<String, dynamic> json) {
    return RestrictionsStatusModel(
      success: json['success'] as bool?,
      message: json['message'] as String?,
      data: json['data'] != null
          ? RestrictionsDataModel.fromJson(
              json['data'] as Map<String, dynamic>,
            )
          : null,
      errors: json['errors'],
    );
  }
}

class RestrictionsDataModel extends RestrictionsDataEntity {
  RestrictionsDataModel({
    super.doctorRestriction,
    super.storageRestriction,
    super.carRestriction,
  });

  factory RestrictionsDataModel.fromJson(Map<String, dynamic> json) {
    return RestrictionsDataModel(
      doctorRestriction: json['doctor_restriction'] != null
          ? DoctorRestrictionModel.fromJson(
              json['doctor_restriction'] as Map<String, dynamic>,
            )
          : null,
      storageRestriction: json['storage_restriction'] != null
          ? StorageRestrictionModel.fromJson(
              json['storage_restriction'] as Map<String, dynamic>,
            )
          : null,
      carRestriction: json['car_restriction'] != null
          ? CarRestrictionModel.fromJson(
              json['car_restriction'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

class DoctorRestrictionModel extends DoctorRestrictionEntity {
  DoctorRestrictionModel({
    super.restrictionType,
    super.doctorIds,
    super.reason,
  });

  factory DoctorRestrictionModel.fromJson(Map<String, dynamic> json) {
    return DoctorRestrictionModel(
      restrictionType: json['restriction_type'] as String?,
      doctorIds: (json['doctor_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'restriction_type': restrictionType,
        'doctor_ids': doctorIds ?? [],
        'reason': reason ?? '',
      };
}

class StorageRestrictionModel extends StorageRestrictionEntity {
  StorageRestrictionModel({
    super.restrictionType,
    super.employeeIds,
    super.reason,
  });

  factory StorageRestrictionModel.fromJson(Map<String, dynamic> json) {
    return StorageRestrictionModel(
      restrictionType: json['restriction_type'] as String?,
      employeeIds: (json['employee_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'restriction_type': restrictionType,
        'employee_ids': employeeIds ?? [],
        'reason': reason ?? '',
      };
}

class CarRestrictionModel extends CarRestrictionEntity {
  CarRestrictionModel({super.status, super.reason});

  factory CarRestrictionModel.fromJson(Map<String, dynamic> json) {
    return CarRestrictionModel(
      status: json['status'] as bool?,
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status ?? false,
        'reason': reason ?? '',
      };
}

// ─── Person List Models ────────────────────────────────────────────────────

class PersonModel extends PersonEntity {
  PersonModel({super.id, super.name, super.email});

  factory PersonModel.fromJson(Map<String, dynamic> json) {
    return PersonModel(
      id: json['id'] as String?,
      name: (json['full_name'] ?? json['name'] ?? json['username']) as String?,
      email: json['email'] as String?,
    );
  }
}
