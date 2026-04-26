import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/repos/restrictions_repository.dart';
import 'restrictions_state.dart';

/// RestrictionsCubit — ViewModel for the Restrictions Tab
///
/// Responsibilities:
///  - Load current restriction status from API
///  - Toggle global restrictions (NONE ↔ GLOBAL)
///  - Manage partial selection lists with search
///  - Apply partial restrictions per domain
///  - Track per-action loading to prevent double taps
@injectable
class RestrictionsCubit extends Cubit<RestrictionsState> {
  final RestrictionsRepository _repository;

  RestrictionsCubit(this._repository) : super(RestrictionsInitial());

  // ─── Initial load ──────────────────────────────────────────────────────

  Future<void> loadData() async {
    emit(RestrictionsLoading());
    await _fetchStatus();
  }

  Future<void> refresh() async {
    emit(RestrictionsLoading());
    await _fetchStatus();
  }

  Future<void> _fetchStatus() async {
    final result = await _repository.getRestrictionsStatus();
    result.fold(
      (failure) => emit(RestrictionsError(
        failure.errorMessage,
        isNetwork: failure is NetworkError,
      )),
      (entity) {
        final data = entity.data;
        final doctor = data?.doctorRestriction;
        final storage = data?.storageRestriction;
        final car = data?.carRestriction;

        emit(RestrictionsLoaded(
          doctorRestrictionType: RestrictionTypeX.fromString(
            doctor?.restrictionType,
          ),
          storageRestrictionType: RestrictionTypeX.fromString(
            storage?.restrictionType,
          ),
          carRestricted: car?.status ?? false,
          selectedDoctorIds: Set<String>.from(doctor?.doctorIds ?? []),
          selectedStorageIds: Set<String>.from(storage?.employeeIds ?? []),
        ));
      },
    );
  }

  // ─── Global toggles ────────────────────────────────────────────────────

  /// Toggle doctor samples NONE ↔ GLOBAL
  Future<void> toggleDoctorGlobal(bool value) async {
    final s = _loaded;
    if (s == null || s.isDoctorLoading) return;

    final targetType = value ? RestrictionType.global : RestrictionType.none;
    emit(s.copyWith(isDoctorLoading: true));

    final result = await _repository.restrictDoctorSamples(type: targetType);
    result.fold(
      (f) => emit(s.copyWith(isDoctorLoading: false)),
      (_) => emit(s.copyWith(
        doctorRestrictionType: targetType,
        // collapse partial panel when going global/none
        isDoctorPartialExpanded: false,
        isDoctorLoading: false,
      )),
    );
  }

  /// Toggle storage samples NONE ↔ GLOBAL
  Future<void> toggleStorageGlobal(bool value) async {
    final s = _loaded;
    if (s == null || s.isStorageLoading) return;

    final targetType = value ? RestrictionType.global : RestrictionType.none;
    emit(s.copyWith(isStorageLoading: true));

    final result = await _repository.restrictStorageSamples(type: targetType);
    result.fold(
      (f) => emit(s.copyWith(isStorageLoading: false)),
      (_) => emit(s.copyWith(
        storageRestrictionType: targetType,
        isStoragePartialExpanded: false,
        isStorageLoading: false,
      )),
    );
  }

  /// Toggle transport car restriction
  Future<void> toggleCarRestriction(bool value, {String reason = ''}) async {
    final s = _loaded;
    if (s == null || s.isCarLoading) return;

    emit(s.copyWith(isCarLoading: true));

    final result = await _repository.restrictTransportCar(
      status: value,
      reason: reason,
    );
    result.fold(
      (f) => emit(s.copyWith(isCarLoading: false)),
      (_) => emit(s.copyWith(carRestricted: value, isCarLoading: false)),
    );
  }

  // ─── Partial section expansion ─────────────────────────────────────────

  Future<void> toggleDoctorPartialExpanded() async {
    final s = _loaded;
    if (s == null) return;

    final willExpand = !s.isDoctorPartialExpanded;
    emit(s.copyWith(isDoctorPartialExpanded: willExpand));

    // Lazy-load doctor list the first time the panel opens
    if (willExpand && s.doctors.isEmpty) {
      await _loadDoctors();
    }
  }

  Future<void> toggleStoragePartialExpanded() async {
    final s = _loaded;
    if (s == null) return;

    final willExpand = !s.isStoragePartialExpanded;
    emit(s.copyWith(isStoragePartialExpanded: willExpand));

    // Lazy-load storage list the first time
    if (willExpand && s.storageEmployees.isEmpty) {
      await _loadStorageEmployees();
    }
  }

  // ─── Load person lists ──────────────────────────────────────────────────

  Future<void> _loadDoctors() async {
    final s = _loaded;
    if (s == null) return;

    emit(s.copyWith(isDoctorListLoading: true));
    final result = await _repository.getDoctors();
    result.fold(
      (f) {
        final cur = _loaded;
        if (cur != null) emit(cur.copyWith(isDoctorListLoading: false));
      },
      (doctors) {
        final cur = _loaded;
        if (cur != null) {
          emit(cur.copyWith(doctors: doctors, isDoctorListLoading: false));
        }
      },
    );
  }

  Future<void> _loadStorageEmployees() async {
    final s = _loaded;
    if (s == null) return;

    emit(s.copyWith(isStorageListLoading: true));
    final result = await _repository.getStorageEmployees();
    result.fold(
      (f) {
        final cur = _loaded;
        if (cur != null) emit(cur.copyWith(isStorageListLoading: false));
      },
      (employees) {
        final cur = _loaded;
        if (cur != null) {
          emit(cur.copyWith(
            storageEmployees: employees,
            isStorageListLoading: false,
          ));
        }
      },
    );
  }

  // ─── Partial selection toggles ─────────────────────────────────────────

  void toggleDoctorSelection(String doctorId) {
    final s = _loaded;
    if (s == null) return;

    final updated = Set<String>.from(s.selectedDoctorIds);
    if (updated.contains(doctorId)) {
      updated.remove(doctorId);
    } else {
      updated.add(doctorId);
    }
    emit(s.copyWith(selectedDoctorIds: updated));
  }

  void toggleStorageSelection(String employeeId) {
    final s = _loaded;
    if (s == null) return;

    final updated = Set<String>.from(s.selectedStorageIds);
    if (updated.contains(employeeId)) {
      updated.remove(employeeId);
    } else {
      updated.add(employeeId);
    }
    emit(s.copyWith(selectedStorageIds: updated));
  }

  void selectAllDoctors() {
    final s = _loaded;
    if (s == null) return;
    final allIds = s.doctors.map((d) => d.id ?? '').toSet();
    emit(s.copyWith(selectedDoctorIds: allIds));
  }

  void clearAllDoctors() {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(selectedDoctorIds: {}));
  }

  void selectAllStorageEmployees() {
    final s = _loaded;
    if (s == null) return;
    final allIds = s.storageEmployees.map((e) => e.id ?? '').toSet();
    emit(s.copyWith(selectedStorageIds: allIds));
  }

  void clearAllStorageEmployees() {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(selectedStorageIds: {}));
  }

  // ─── Apply partial restrictions ────────────────────────────────────────

  Future<void> applyPartialDoctorRestriction({String reason = ''}) async {
    final s = _loaded;
    if (s == null || s.isDoctorLoading) return;

    emit(s.copyWith(isDoctorLoading: true));
    final ids = s.selectedDoctorIds.toList();
    final result = await _repository.restrictDoctorSamples(
      type: RestrictionType.partial,
      doctorIds: ids,
      reason: reason,
    );
    result.fold(
      (f) {
        final cur = _loaded;
        if (cur != null) emit(cur.copyWith(isDoctorLoading: false));
      },
      (_) {
        final cur = _loaded;
        if (cur != null) {
          emit(cur.copyWith(
            doctorRestrictionType: RestrictionType.partial,
            isDoctorLoading: false,
          ));
        }
      },
    );
  }

  Future<void> applyPartialStorageRestriction({String reason = ''}) async {
    final s = _loaded;
    if (s == null || s.isStorageLoading) return;

    emit(s.copyWith(isStorageLoading: true));
    final ids = s.selectedStorageIds.toList();
    final result = await _repository.restrictStorageSamples(
      type: RestrictionType.partial,
      employeeIds: ids,
      reason: reason,
    );
    result.fold(
      (f) {
        final cur = _loaded;
        if (cur != null) emit(cur.copyWith(isStorageLoading: false));
      },
      (_) {
        final cur = _loaded;
        if (cur != null) {
          emit(cur.copyWith(
            storageRestrictionType: RestrictionType.partial,
            isStorageLoading: false,
          ));
        }
      },
    );
  }

  // ─── Search ────────────────────────────────────────────────────────────

  void updateDoctorSearch(String query) {
    final s = _loaded;
    if (s != null) emit(s.copyWith(doctorSearchQuery: query));
  }

  void updateStorageSearch(String query) {
    final s = _loaded;
    if (s != null) emit(s.copyWith(storageSearchQuery: query));
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  RestrictionsLoaded? get _loaded =>
      state is RestrictionsLoaded ? state as RestrictionsLoaded : null;
}
