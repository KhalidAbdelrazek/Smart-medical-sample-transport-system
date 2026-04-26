import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

abstract class RestrictionsState {}

class RestrictionsInitial extends RestrictionsState {}

class RestrictionsLoading extends RestrictionsState {}

class RestrictionsError extends RestrictionsState {
  final String message;
  final bool isNetwork;
  RestrictionsError(this.message, {this.isNetwork = false});
}

class RestrictionsLoaded extends RestrictionsState {
  final List<PersonEntity> doctors;
  final List<PersonEntity> storageEmployees;
  final bool carRestricted;

  // Section Expansion
  final bool isDoctorExpanded;
  final bool isStorageExpanded;

  // Loading flags for individual sections
  final bool isDoctorLoading;
  final bool isStorageLoading;
  final bool isCarLoading;

  RestrictionsLoaded({
    this.doctors = const [],
    this.storageEmployees = const [],
    this.carRestricted = false,
    this.isDoctorExpanded = false,
    this.isStorageExpanded = false,
    this.isDoctorLoading = false,
    this.isStorageLoading = false,
    this.isCarLoading = false,
  });

  // Computed Properties for Global Toggles
  bool get isAllDoctorsRestricted =>
      doctors.isNotEmpty && doctors.every((d) => d.isRestricted);

  bool get isAllStorageRestricted =>
      storageEmployees.isNotEmpty && storageEmployees.every((e) => e.isRestricted);

  RestrictionsLoaded copyWith({
    List<PersonEntity>? doctors,
    List<PersonEntity>? storageEmployees,
    bool? carRestricted,
    bool? isDoctorExpanded,
    bool? isStorageExpanded,
    bool? isDoctorLoading,
    bool? isStorageLoading,
    bool? isCarLoading,
  }) {
    return RestrictionsLoaded(
      doctors: doctors ?? this.doctors,
      storageEmployees: storageEmployees ?? this.storageEmployees,
      carRestricted: carRestricted ?? this.carRestricted,
      isDoctorExpanded: isDoctorExpanded ?? this.isDoctorExpanded,
      isStorageExpanded: isStorageExpanded ?? this.isStorageExpanded,
      isDoctorLoading: isDoctorLoading ?? this.isDoctorLoading,
      isStorageLoading: isStorageLoading ?? this.isStorageLoading,
      isCarLoading: isCarLoading ?? this.isCarLoading,
    );
  }
}
