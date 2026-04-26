// ─── Restriction Type ──────────────────────────────────────────────────────

enum RestrictionType { none, global, partial }

extension RestrictionTypeX on RestrictionType {
  String get value {
    switch (this) {
      case RestrictionType.none:
        return 'NONE';
      case RestrictionType.global:
        return 'GLOBAL';
      case RestrictionType.partial:
        return 'PARTIAL';
    }
  }

  static RestrictionType fromString(String? s) {
    switch (s?.toUpperCase()) {
      case 'GLOBAL':
        return RestrictionType.global;
      case 'PARTIAL':
        return RestrictionType.partial;
      default:
        return RestrictionType.none;
    }
  }
}

// ─── Restrictions Status ───────────────────────────────────────────────────

class RestrictionsStatusEntity {
  final bool? success;
  final String? message;
  final RestrictionsDataEntity? data;
  final dynamic errors;

  RestrictionsStatusEntity({
    this.success,
    this.message,
    this.data,
    this.errors,
  });
}

class RestrictionsDataEntity {
  final DoctorRestrictionEntity? doctorRestriction;
  final StorageRestrictionEntity? storageRestriction;
  final CarRestrictionEntity? carRestriction;

  RestrictionsDataEntity({
    this.doctorRestriction,
    this.storageRestriction,
    this.carRestriction,
  });
}

class DoctorRestrictionEntity {
  final String? restrictionType;
  final List<String>? doctorIds;
  final String? reason;

  DoctorRestrictionEntity({
    this.restrictionType,
    this.doctorIds,
    this.reason,
  });

  RestrictionType get type =>
      RestrictionTypeX.fromString(restrictionType);
}

class StorageRestrictionEntity {
  final String? restrictionType;
  final List<String>? employeeIds;
  final String? reason;

  StorageRestrictionEntity({
    this.restrictionType,
    this.employeeIds,
    this.reason,
  });

  RestrictionType get type =>
      RestrictionTypeX.fromString(restrictionType);
}

class CarRestrictionEntity {
  final bool? status;
  final String? reason;

  CarRestrictionEntity({this.status, this.reason});
}

// ─── Person (doctor / storage employee) ───────────────────────────────────

class PersonEntity {
  final String? id;
  final String? name;
  final String? email;

  PersonEntity({this.id, this.name, this.email});
}
