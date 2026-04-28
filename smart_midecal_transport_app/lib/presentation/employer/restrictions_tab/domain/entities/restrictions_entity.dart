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

// ─── Restrictions Status ───────────────────────────────────────────────────

class PersonEntity {
  final String? id;
  final String? name;
  final String? email;
  final bool isRestricted;

  PersonEntity({
    this.id,
    this.name,
    this.email,
    this.isRestricted = false,
  });

  PersonEntity copyWith({
    String? id,
    String? name,
    String? email,
    bool? isRestricted,
  }) {
    return PersonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }
}
