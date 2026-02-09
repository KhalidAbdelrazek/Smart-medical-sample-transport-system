/// States for Restrictions Tab
abstract class RestrictionsState {}

class RestrictionsInitial extends RestrictionsState {}

class RestrictionsLoading extends RestrictionsState {}

class RestrictionsLoaded extends RestrictionsState {
  final bool restrictDoctorSamples;
  final bool restrictDoctorBags;
  final bool restrictStorageAddBags;
  final bool restrictStorageAddSamples;
  final bool restrictTransportCarItems;

  RestrictionsLoaded({
    required this.restrictDoctorSamples,
    required this.restrictDoctorBags,
    required this.restrictStorageAddBags,
    required this.restrictStorageAddSamples,
    required this.restrictTransportCarItems,
  });

  /// Copy with method for updating individual restrictions
  RestrictionsLoaded copyWith({
    bool? restrictDoctorSamples,
    bool? restrictDoctorBags,
    bool? restrictStorageAddBags,
    bool? restrictStorageAddSamples,
    bool? restrictTransportCarItems,
  }) {
    return RestrictionsLoaded(
      restrictDoctorSamples:
          restrictDoctorSamples ?? this.restrictDoctorSamples,
      restrictDoctorBags: restrictDoctorBags ?? this.restrictDoctorBags,
      restrictStorageAddBags:
          restrictStorageAddBags ?? this.restrictStorageAddBags,
      restrictStorageAddSamples:
          restrictStorageAddSamples ?? this.restrictStorageAddSamples,
      restrictTransportCarItems:
          restrictTransportCarItems ?? this.restrictTransportCarItems,
    );
  }
}

class RestrictionsError extends RestrictionsState {
  final String message;
  RestrictionsError(this.message);
}
