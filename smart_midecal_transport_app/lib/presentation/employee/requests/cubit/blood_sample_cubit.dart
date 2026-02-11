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
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  String? selectedBloodType;
  String urgency = 'normal';

  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  /// Load recent requests with skeleton loading
  Future<void> loadData() async {
    emit(BloodSampleLoading());
    await _fetchData();
  }

  /// Refresh data silently
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      emit(BloodSampleLoaded(recentRequests: _generateDummyRequests()));
    } catch (e) {
      emit(BloodSampleError('Failed to load sample requests'));
    }
  }

  /// Submit a blood sample request
  Future<void> submitRequest() async {
    emit(BloodSampleSubmitting());
    try {
      await Future.delayed(const Duration(seconds: 1));
      // Clear form after submission
      patientController.clear();
      locationController.clear();
      notesController.clear();
      selectedBloodType = null;
      urgency = 'normal';
      await _fetchData();
    } catch (e) {
      emit(BloodSampleError('Failed to submit request'));
    }
  }

  List<Map<String, dynamic>> _generateDummyRequests() {
    return [
      {
        'name': 'John Doe',
        'blood': 'O+',
        'time': '2 hours ago',
        'status': 'pending',
      },
      {
        'name': 'Jane Smith',
        'blood': 'A-',
        'time': '5 hours ago',
        'status': 'completed',
      },
      {
        'name': 'Bob Wilson',
        'blood': 'B+',
        'time': '1 day ago',
        'status': 'completed',
      },
    ];
  }

  @override
  Future<void> close() {
    patientController.dispose();
    locationController.dispose();
    notesController.dispose();
    return super.close();
  }
}
