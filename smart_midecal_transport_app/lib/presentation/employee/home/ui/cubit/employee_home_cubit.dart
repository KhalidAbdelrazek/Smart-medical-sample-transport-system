import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/repos/static_repo.dart';


import 'employee_home_state.dart';

@injectable
class EmployeeHomeCubit extends Cubit<EmployeeHomeState> {
  final EmploeeStatisticsRepo repo;

  EmployeeHomeCubit(this.repo) : super(EmployeeHomeInitial());

  /// Load dashboard data with loading state
  Future<void> loadData() async {
    emit(EmployeeHomeLoading());
    await _fetchData();
  }

  /// Refresh silently
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await repo.getStatistics();

      result.fold(
        (failure) {
          emit(EmployeeHomeError(failure.errorMessage));
        },
        (data) {
          emit(
            EmployeeHomeLoaded(
              /// 🔥 REAL DATA FROM API
              totalBloodBagsRequested: data.totalRequests,
              completedRequests: data.successfulRequests,
              pendingRequests: data.pendingRequests,

              /// ❗ NOT IN API → TEMP VALUES
              totalSamplesRequested: 0,
              todayBloodBags: 0,
              todaySamples: 0,
              bloodBagsByType: {},
            ),
          );
        },
      );
    } catch (e) {
      emit(EmployeeHomeError('Failed to load dashboard data'));
    }
  }
}