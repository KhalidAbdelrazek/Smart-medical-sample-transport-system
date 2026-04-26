import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';

/// Base state
abstract class RestrictionsState {}

class RestrictionsInitial extends RestrictionsState {}

class RestrictionsLoading extends RestrictionsState {}

class RestrictionsError extends RestrictionsState {
  final String message;
  final bool isNetwork;
  RestrictionsError(this.message, {this.isNetwork = false});
}

// ─── Loaded ────────────────────────────────────────────────────────────────

class RestrictionsLoaded extends RestrictionsState {
  // ── Global restriction types ─────────────────────────────────────────────
  final RestrictionType doctorRestrictionType;
  final RestrictionType storageRestrictionType;
  final bool carRestricted;

  // ── Partial-selection lists ──────────────────────────────────────────────
  final List<PersonEntity> doctors;
  final List<PersonEntity> storageEmployees;

  /// IDs currently toggled ON for partial restriction
  final Set<String> selectedDoctorIds;
  final Set<String> selectedStorageIds;

  // ── Expansion state ──────────────────────────────────────────────────────
  final bool isDoctorPartialExpanded;
  final bool isStoragePartialExpanded;

  // ── Per-action loading flags (prevent double taps) ───────────────────────
  final bool isDoctorLoading;
  final bool isStorageLoading;
  final bool isCarLoading;
  final bool isDoctorListLoading;
  final bool isStorageListLoading;

  // ── Search queries ───────────────────────────────────────────────────────
  final String doctorSearchQuery;
  final String storageSearchQuery;

  // ── Reason fields ─────────────────────────────────────────────────────────
  final String carReason;

  RestrictionsLoaded({
    required this.doctorRestrictionType,
    required this.storageRestrictionType,
    required this.carRestricted,
    this.doctors = const [],
    this.storageEmployees = const [],
    this.selectedDoctorIds = const {},
    this.selectedStorageIds = const {},
    this.isDoctorPartialExpanded = false,
    this.isStoragePartialExpanded = false,
    this.isDoctorLoading = false,
    this.isStorageLoading = false,
    this.isCarLoading = false,
    this.isDoctorListLoading = false,
    this.isStorageListLoading = false,
    this.doctorSearchQuery = '',
    this.storageSearchQuery = '',
    this.carReason = '',
  });

  // ── Derived helpers ──────────────────────────────────────────────────────

  bool get isDoctorGloballyRestricted =>
      doctorRestrictionType == RestrictionType.global;

  bool get isStorageGloballyRestricted =>
      storageRestrictionType == RestrictionType.global;

  List<PersonEntity> get filteredDoctors {
    if (doctorSearchQuery.isEmpty) return doctors;
    final q = doctorSearchQuery.toLowerCase();
    return doctors
        .where(
          (d) =>
              (d.name?.toLowerCase().contains(q) ?? false) ||
              (d.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  List<PersonEntity> get filteredStorageEmployees {
    if (storageSearchQuery.isEmpty) return storageEmployees;
    final q = storageSearchQuery.toLowerCase();
    return storageEmployees
        .where(
          (e) =>
              (e.name?.toLowerCase().contains(q) ?? false) ||
              (e.email?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  RestrictionsLoaded copyWith({
    RestrictionType? doctorRestrictionType,
    RestrictionType? storageRestrictionType,
    bool? carRestricted,
    List<PersonEntity>? doctors,
    List<PersonEntity>? storageEmployees,
    Set<String>? selectedDoctorIds,
    Set<String>? selectedStorageIds,
    bool? isDoctorPartialExpanded,
    bool? isStoragePartialExpanded,
    bool? isDoctorLoading,
    bool? isStorageLoading,
    bool? isCarLoading,
    bool? isDoctorListLoading,
    bool? isStorageListLoading,
    String? doctorSearchQuery,
    String? storageSearchQuery,
    String? carReason,
  }) {
    return RestrictionsLoaded(
      doctorRestrictionType:
          doctorRestrictionType ?? this.doctorRestrictionType,
      storageRestrictionType:
          storageRestrictionType ?? this.storageRestrictionType,
      carRestricted: carRestricted ?? this.carRestricted,
      doctors: doctors ?? this.doctors,
      storageEmployees: storageEmployees ?? this.storageEmployees,
      selectedDoctorIds: selectedDoctorIds ?? this.selectedDoctorIds,
      selectedStorageIds: selectedStorageIds ?? this.selectedStorageIds,
      isDoctorPartialExpanded:
          isDoctorPartialExpanded ?? this.isDoctorPartialExpanded,
      isStoragePartialExpanded:
          isStoragePartialExpanded ?? this.isStoragePartialExpanded,
      isDoctorLoading: isDoctorLoading ?? this.isDoctorLoading,
      isStorageLoading: isStorageLoading ?? this.isStorageLoading,
      isCarLoading: isCarLoading ?? this.isCarLoading,
      isDoctorListLoading: isDoctorListLoading ?? this.isDoctorListLoading,
      isStorageListLoading: isStorageListLoading ?? this.isStorageListLoading,
      doctorSearchQuery: doctorSearchQuery ?? this.doctorSearchQuery,
      storageSearchQuery: storageSearchQuery ?? this.storageSearchQuery,
      carReason: carReason ?? this.carReason,
    );
  }
}
