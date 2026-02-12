import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'employer_profile_state.dart';

/// Cubit for Employer Profile Tab
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
@injectable
class EmployerProfileCubit extends Cubit<EmployerProfileState> {
  EmployerProfileCubit() : super(EmployerProfileInitial());

  /// Load employer profile data with skeleton loading state
  Future<void> loadData() async {
    emit(EmployerProfileLoading());
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

      // Generate dummy employer profile data
      emit(
        EmployerProfileLoaded(
          employerId: 'EMP-ADM-001',
          employerName: 'Dr. Mohamed Ali',
          mainRole: 'Hospital Administrator',
          department: 'Medical Administration',
          email: 'mohamed.ali@hospital.com',
          joinDate: 'January 15, 2023',
        ),
      );
    } catch (e) {
      emit(EmployerProfileError('Failed to load profile'));
    }
  }
}
