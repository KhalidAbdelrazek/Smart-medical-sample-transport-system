import 'package:flutter_bloc/flutter_bloc.dart';
import 'employee_home_state.dart';

/// Cubit for Employee Home Dashboard Tab
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
/// All analytics calculations happen here (ViewModel logic)
class EmployeeHomeCubit extends Cubit<EmployeeHomeState> {
  EmployeeHomeCubit() : super(EmployeeHomeInitial());

  /// Load dashboard data with skeleton loading state
  Future<void> loadData() async {
    emit(EmployeeHomeLoading());
    await _fetchData();
  }

  /// Refresh data silently (no skeleton, keeps current data visible)
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate dummy employee analytics data
      final bloodBagsByType = _generateBloodBagsByType();
      final totalBags = _calculateTotal(bloodBagsByType);

      emit(
        EmployeeHomeLoaded(
          totalBloodBagsRequested: totalBags,
          totalSamplesRequested: 87,
          todayBloodBags: 12,
          todaySamples: 8,
          pendingRequests: 15,
          completedRequests: 142,
          bloodBagsByType: bloodBagsByType,
        ),
      );
    } catch (e) {
      emit(EmployeeHomeError('Failed to load dashboard data'));
    }
  }

  /// Generate dummy blood bags data by blood type
  Map<String, int> _generateBloodBagsByType() {
    return {
      'A+': 28,
      'A-': 7,
      'B+': 22,
      'B-': 5,
      'AB+': 10,
      'AB-': 3,
      'O+': 35,
      'O-': 12,
    };
  }

  /// Calculate total from type map
  int _calculateTotal(Map<String, int> byType) {
    return byType.values.fold(0, (sum, count) => sum + count);
  }
}
