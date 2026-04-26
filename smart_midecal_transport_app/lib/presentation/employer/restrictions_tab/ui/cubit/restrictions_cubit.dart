import 'package:either_dart/either.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/entities/restrictions_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employer/restrictions_tab/domain/repos/restrictions_repository.dart';
import 'restrictions_state.dart';

@injectable
class RestrictionsCubit extends Cubit<RestrictionsState> {
  final RestrictionsRepository _repository;

  RestrictionsCubit(this._repository) : super(RestrictionsInitial());

  // ─── Initial load ──────────────────────────────────────────────────────

  Future<void> loadData() async {
    emit(RestrictionsLoading());
    await _fetchAll();
  }

  Future<void> refresh() async {
    await _fetchAll();
  }

  Future<void> _fetchAll() async {
    final results = await Future.wait([
      _repository.getRestrictionsStatus(type: 'doctor'),
      _repository.getRestrictionsStatus(type: 'storage'),
    ]);

    final doctorResult = results[0];
    final storageResult = results[1];

    List<PersonEntity>? doctors;
    List<PersonEntity>? storage;

    doctorResult.fold(
      (failure) {
        emit(RestrictionsError(failure.errorMessage, isNetwork: failure is NetworkError));
      },
      (list) => doctors = list,
    );

    if (state is RestrictionsError) return;

    storageResult.fold(
      (failure) {
        emit(RestrictionsError(failure.errorMessage, isNetwork: failure is NetworkError));
      },
      (list) => storage = list,
    );

    if (state is RestrictionsError) return;

    if (doctors != null && storage != null) {
      emit(RestrictionsLoaded(
        doctors: doctors!,
        storageEmployees: storage!,
      ));
    }
  }

  // ─── Global toggles ────────────────────────────────────────────────────

  Future<void> toggleDoctorGlobal(bool value) async {
    final s = _loaded;
    if (s == null || s.isDoctorLoading) return;

    emit(s.copyWith(isDoctorLoading: true));
    final targetType = value ? RestrictionType.globalRestrict : RestrictionType.allUnrestrict;

    final result = await _repository.restrictDoctorSamples(type: targetType);
    result.fold(
      (f) => emit(s.copyWith(isDoctorLoading: false)),
      (_) async {
        // Refresh full list to get updated status
        final refreshResult = await _repository.getRestrictionsStatus(type: 'doctor');
        refreshResult.fold(
          (f) => emit(s.copyWith(isDoctorLoading: false)),
          (list) => emit(s.copyWith(doctors: list, isDoctorLoading: false)),
        );
      },
    );
  }

  Future<void> toggleStorageGlobal(bool value) async {
    final s = _loaded;
    if (s == null || s.isStorageLoading) return;

    emit(s.copyWith(isStorageLoading: true));
    final targetType = value ? RestrictionType.globalRestrict : RestrictionType.allUnrestrict;

    final result = await _repository.restrictStorageSamples(type: targetType);
    result.fold(
      (f) => emit(s.copyWith(isStorageLoading: false)),
      (_) async {
        final refreshResult = await _repository.getRestrictionsStatus(type: 'storage');
        refreshResult.fold(
          (f) => emit(s.copyWith(isStorageLoading: false)),
          (list) => emit(s.copyWith(storageEmployees: list, isStorageLoading: false)),
        );
      },
    );
  }

  Future<void> toggleCarRestriction(bool value, {String reason = ''}) async {
    final s = _loaded;
    if (s == null || s.isCarLoading) return;

    emit(s.copyWith(isCarLoading: true));
    final result = await _repository.restrictTransportCar(status: value, reason: reason);
    result.fold(
      (f) => emit(s.copyWith(isCarLoading: false)),
      (_) => emit(s.copyWith(carRestricted: value, isCarLoading: false)),
    );
  }

  // ─── Individual toggles ───────────────────────────────────────────────

  Future<void> toggleIndividualDoctor(String id, bool value) async {
    final s = _loaded;
    if (s == null || s.isDoctorLoading) return;

    emit(s.copyWith(isDoctorLoading: true));
    final targetType = value ? RestrictionType.partialRestrict : RestrictionType.partialUnrestrict;

    final result = await _repository.restrictDoctorSamples(
      type: targetType,
      userIds: [id],
    );

    result.fold(
      (f) => emit(s.copyWith(isDoctorLoading: false)),
      (_) {
        final updated = s.doctors.map((d) {
          if (d.id == id) return d.copyWith(isRestricted: value);
          return d;
        }).toList();
        emit(s.copyWith(doctors: updated, isDoctorLoading: false));
      },
    );
  }

  Future<void> toggleIndividualStorage(String id, bool value) async {
    final s = _loaded;
    if (s == null || s.isStorageLoading) return;

    emit(s.copyWith(isStorageLoading: true));
    final targetType = value ? RestrictionType.partialRestrict : RestrictionType.partialUnrestrict;

    final result = await _repository.restrictStorageSamples(
      type: targetType,
      userIds: [id],
    );

    result.fold(
      (f) => emit(s.copyWith(isStorageLoading: false)),
      (_) {
        final updated = s.storageEmployees.map((e) {
          if (e.id == id) return e.copyWith(isRestricted: value);
          return e;
        }).toList();
        emit(s.copyWith(storageEmployees: updated, isStorageLoading: false));
      },
    );
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────

  void toggleDoctorExpanded() {
    final s = _loaded;
    if (s != null) emit(s.copyWith(isDoctorExpanded: !s.isDoctorExpanded));
  }

  void toggleStorageExpanded() {
    final s = _loaded;
    if (s != null) emit(s.copyWith(isStorageExpanded: !s.isStorageExpanded));
  }

  RestrictionsLoaded? get _loaded =>
      state is RestrictionsLoaded ? state as RestrictionsLoaded : null;
}
