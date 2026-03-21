import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'profile_state.dart';

/// Cubit for Profile Tab
@injectable
class ProfileCubit extends Cubit<ProfileState> {
  ProfileCubit() : super(ProfileInitial());

  /// Load profile data
  Future<void> loadData() async {
    emit(ProfileLoading());
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(
        ProfileLoaded(
          employeeName: 'Ahmed Hassan',
          employeeId: 'EMP-2847',
          department: 'Blood Storage',
          role: 'Storage Specialist',
          shift: 'Morning (7:00 - 15:00)',
          todayBagsProcessed: 12,
          todaySamplesProcessed: 8,
          todayCarsDispatched: 4,
        ),
      );
    } catch (e) {
      emit(ProfileError('Failed to load profile'));
    }
  }

  /// Refresh profile (pull-to-refresh)
  Future<void> refresh() async {
    await loadData();
  }
}
