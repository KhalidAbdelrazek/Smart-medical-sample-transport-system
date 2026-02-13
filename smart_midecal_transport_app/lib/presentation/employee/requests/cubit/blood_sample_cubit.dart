import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'blood_sample_state.dart';

/// Cubit for Blood Sample Requests
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
/// - submitRequest(): Handles form submission
@injectable
class BloodSampleCubit extends Cubit<BloodSampleState> {
  BloodSampleCubit() : super(BloodSampleInitial());

  final TextEditingController patientController = TextEditingController();

  String? selectedRoom;

  final List<String> rooms = ['Room A', 'Room B', 'Room C'];

  /// Load initial data
  Future<void> loadData() async {
    emit(BloodSampleLoading());
    await Future.delayed(const Duration(milliseconds: 500));
    emit(BloodSampleLoaded());
  }

  /// Refresh data silently
  Future<void> refresh() async {
    emit(BloodSampleLoaded());
  }

  /// Submit a blood sample request
  Future<void> submitRequest() async {
    final patient = patientController.text;

    if (patient.isEmpty) {
      emit(BloodSampleError('Please enter Patient Name or ID'));
      emit(BloodSampleLoaded());
      return;
    }

    if (selectedRoom == null) {
      emit(BloodSampleError('Please select a room'));
      emit(BloodSampleLoaded());
      return;
    }

    emit(BloodSampleSubmitting());
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));

      // Clear form after submission
      patientController.clear();
      selectedRoom = null;

      // Re-emit loaded state
      emit(BloodSampleLoaded());
    } catch (e) {
      emit(BloodSampleError('Failed to submit request'));
    }
  }

  @override
  Future<void> close() {
    patientController.dispose();
    return super.close();
  }
}
