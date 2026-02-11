import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'employee_profile_state.dart';

/// Cubit for Employee Profile Tab
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
@injectable
class EmployeeProfileCubit extends Cubit<EmployeeProfileState> {
  EmployeeProfileCubit() : super(EmployeeProfileInitial());

  /// Load profile data with skeleton loading
  Future<void> loadData() async {
    emit(EmployeeProfileLoading());
    await _fetchData();
  }

  /// Refresh data silently
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      emit(
        EmployeeProfileLoaded(
          name: 'Ahmed Mohamed',
          role: 'Transport Specialist',
          employeeId: 'EMP-2024-0147',
          department: 'Blood Bank Logistics',
          email: 'ahmed.m@hospital.org',
          shift: 'Morning (7:00 AM - 3:00 PM)',
          joinDate: 'Jan 15, 2024',
        ),
      );
    } catch (e) {
      emit(EmployeeProfileError('Failed to load profile'));
    }
  }
}
