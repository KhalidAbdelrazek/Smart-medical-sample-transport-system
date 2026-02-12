import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'blood_bag_state.dart';

/// Cubit for Blood Bag Requests
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
/// - submitRequest(): Handles form submission
@injectable
class BloodBagCubit extends Cubit<BloodBagState> {
  BloodBagCubit() : super(BloodBagInitial());

  final TextEditingController quantityController = TextEditingController();
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
    emit(BloodBagLoading());
    await _fetchData();
  }

  /// Refresh data silently
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      emit(BloodBagLoaded(recentRequests: _generateDummyRequests()));
    } catch (e) {
      emit(BloodBagError('Failed to load bag requests'));
    }
  }

  /// Submit a blood bag request
  Future<void> submitRequest() async {
    emit(BloodBagSubmitting());
    try {
      await Future.delayed(const Duration(seconds: 1));
      // Clear form after submission
      quantityController.clear();
      locationController.clear();
      notesController.clear();
      selectedBloodType = null;
      urgency = 'normal';
      await _fetchData();
    } catch (e) {
      emit(BloodBagError('Failed to submit request'));
    }
  }

  List<Map<String, dynamic>> _generateDummyRequests() {
    return [
      {
        'blood': 'O+',
        'quantity': '3 units',
        'time': '1 hour ago',
        'status': 'pending',
      },
      {
        'blood': 'AB+',
        'quantity': '2 units',
        'time': '3 hours ago',
        'status': 'completed',
      },
      {
        'blood': 'A-',
        'quantity': '5 units',
        'time': '1 day ago',
        'status': 'completed',
      },
    ];
  }

  @override
  Future<void> close() {
    quantityController.dispose();
    locationController.dispose();
    notesController.dispose();
    return super.close();
  }
}
