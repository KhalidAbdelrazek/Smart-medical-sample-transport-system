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
  final List<DoctorsSamplesEntity> doctors;
  final List<StorageSamplesEntity> storageEmployees;
  final bool carRestricted;

  final bool isDoctorExpanded;
  final bool isStorageExpanded;

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

  bool get isAllDoctorsRestricted =>
      doctors.isNotEmpty && doctors.every((d) => d.isRestricted == true);

  bool get isAllStorageRestricted =>
      storageEmployees.isNotEmpty &&
      storageEmployees.every((e) => e.isRestricted == true);

  RestrictionsLoaded copyWith({
    List<DoctorsSamplesEntity>? doctors,
    List<StorageSamplesEntity>? storageEmployees,
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
