import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'restrictions_state.dart';

/// Cubit for Restrictions Tab
/// - All permission toggling logic handled here (ViewModel)
/// - UI only dispatches events, never makes decisions
@injectable
class RestrictionsCubit extends Cubit<RestrictionsState> {
  RestrictionsCubit() : super(RestrictionsInitial());

  /// Load restrictions data with skeleton loading state
  Future<void> loadData() async {
    emit(RestrictionsLoading());
    await _fetchData();
  }

  /// Refresh data silently (no skeleton)
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 1));

      // Load initial dummy restriction states
      emit(
        RestrictionsLoaded(
          restrictDoctorSamples: false,
          restrictDoctorBags: false,
          restrictStorageAddBags: false,
          restrictStorageAddSamples: false,
          restrictTransportCarItems: false,
        ),
      );
    } catch (e) {
      emit(RestrictionsError('Failed to load restrictions'));
    }
  }

  /// Toggle doctor sample restriction
  void toggleDoctorSamples() {
    final currentState = state;
    if (currentState is RestrictionsLoaded) {
      emit(
        currentState.copyWith(
          restrictDoctorSamples: !currentState.restrictDoctorSamples,
        ),
      );
    }
  }

  /// Toggle doctor blood bags restriction
  void toggleDoctorBags() {
    final currentState = state;
    if (currentState is RestrictionsLoaded) {
      emit(
        currentState.copyWith(
          restrictDoctorBags: !currentState.restrictDoctorBags,
        ),
      );
    }
  }

  /// Toggle storage adding bags restriction
  void toggleStorageAddBags() {
    final currentState = state;
    if (currentState is RestrictionsLoaded) {
      emit(
        currentState.copyWith(
          restrictStorageAddBags: !currentState.restrictStorageAddBags,
        ),
      );
    }
  }

  /// Toggle storage adding samples restriction
  void toggleStorageAddSamples() {
    final currentState = state;
    if (currentState is RestrictionsLoaded) {
      emit(
        currentState.copyWith(
          restrictStorageAddSamples: !currentState.restrictStorageAddSamples,
        ),
      );
    }
  }

  /// Toggle transport car items restriction
  void toggleTransportCarItems() {
    final currentState = state;
    if (currentState is RestrictionsLoaded) {
      emit(
        currentState.copyWith(
          restrictTransportCarItems: !currentState.restrictTransportCarItems,
        ),
      );
    }
  }
}
