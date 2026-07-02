import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/repository/requests_repository.dart';
import 'blood_sample_state.dart';

/// Cubit for Blood Sample Requests – supports bulk submissions.
@injectable
class BloodSampleCubit extends Cubit<BloodSampleState> {
  final RequestsRepository requestsRepository;

  BloodSampleCubit({required this.requestsRepository})
    : super(BloodSampleInitial());

  // ── Controllers & transient state ─────────────────────────────
  final TextEditingController searchController = TextEditingController();

  List<SampleEntity> searchResults = [];

  /// Codes of all samples the user has ticked.
  List<String> selectedSampleCodes = [];

  String? selectedRoom;

  // ── Search ────────────────────────────────────────────────────

  /// Search samples by patient ID / code.
  void searchSamples(String query) async {
    if (query.isEmpty) {
      searchResults = [];
      _emitLoaded();
      return;
    }

    emit(BloodSampleSearchLoading());

    final result = await requestsRepository.getSampleById(query);

    result.fold(
      (failure) {
        searchResults = [];
        emit(BloodSampleError(failure.errorMessage));
        _emitLoaded();
      },
      (response) {
        searchResults = response.data!;
        _emitLoaded();
      },
    );
  }

  // ── Selection ─────────────────────────────────────────────────

  /// Toggle a sample code in/out of the selection list.
  void toggleSampleSelection(SampleEntity sample) {
    final code = sample.sampleCode!;
    if (selectedSampleCodes.contains(code)) {
      selectedSampleCodes = List.from(selectedSampleCodes)..remove(code);
    } else {
      selectedSampleCodes = List.from(selectedSampleCodes)..add(code);
    }
    _emitLoaded();
  }

  /// Returns true if the given sample code is currently selected.
  bool isSelected(String sampleCode) =>
      selectedSampleCodes.contains(sampleCode);

  /// Deselect all samples.
  void clearSelections() {
    selectedSampleCodes = [];
    _emitLoaded();
  }

  // ── Room ──────────────────────────────────────────────────────

  void selectRoom(String room) {
    selectedRoom = room;
    _emitLoaded();
  }

  // ── Initial load ──────────────────────────────────────────────

  Future<void> loadData() async {
    emit(BloodSampleLoading());
    await Future.delayed(const Duration(milliseconds: 100));
    _emitLoaded();
  }

  // ── Submit (Bulk) ─────────────────────────────────────────────

  /// Submit a bulk blood sample request.
  /// Validates that at least one sample is selected and a room is chosen.
  Future<void> submitRequest() async {
    if (selectedSampleCodes.isEmpty) {
      emit(
        BloodSampleError(
          'status.please_select_at_least_one_patient_sample'.tr(),
        ),
      );
      _emitLoaded();
      return;
    }

    if (selectedRoom == null) {
      emit(BloodSampleError('status.please_select_room'.tr()));
      _emitLoaded();
      return;
    }

    emit(BloodSampleSubmitting());

    final result = await requestsRepository.requestBulkSamples(
      selectedSampleCodes,
      selectedRoom!,
    );

    result.fold(
      (failure) {
        // ── Case A: Token expired ────────────────────────────────
        if (failure is TokenExpiredFailure) {
          emit(BloodSampleTokenExpired());
          return;
        }
        // ── Case C: Network / server error ───────────────────────
        emit(BloodSampleError(failure.errorMessage));
        _emitLoaded();
      },
      (response) {
        final data = response.data;
        final successCount = data?.successful.length ?? 0;
        final failureCount = data?.failed.length ?? 0;

        // Clear form after API call (regardless of partial failure)
        searchController.clear();
        searchResults = [];
        selectedSampleCodes = [];
        selectedRoom = null;

        // ── Case B: Emit result (full or partial success) ─────────
        emit(
          BloodSampleBulkResult(
            successCount: successCount,
            failureCount: failureCount,
            failures: data?.failed ?? [],
          ),
        );
        _emitLoaded();
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  void _emitLoaded() {
    emit(
      BloodSampleLoaded(
        searchResults: searchResults,
        selectedSampleCodes: List.from(selectedSampleCodes),
        selectedRoom: selectedRoom,
      ),
    );
  }

  @override
  Future<void> close() {
    searchController.dispose();
    return super.close();
  }
}
