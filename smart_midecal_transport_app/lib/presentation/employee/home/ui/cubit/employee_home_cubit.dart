import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/domain/repos/static_repo.dart';

import 'employee_home_state.dart';

@injectable
class EmployeeHomeCubit extends Cubit<EmployeeHomeState> {
  final EmploeeStatisticsRepo repo;

  EmployeeHomeCubit(this.repo) : super(EmployeeHomeInitial());

  /// First load (shows loading)
  Future<void> loadData() async {
    if (state is! EmployeeHomeLoaded) {
      emit(EmployeeHomeLoading());
    }
    await _fetchData();
  }

  /// Pull-to-refresh (no loading spinner)
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
              totalRequests: data.totalRequests,
              successfulRequests: data.successfulRequests,
              failedRequests: data.failedRequests,
              cancelledRequests: data.cancelledRequests,
              pendingRequests: data.pendingRequests,
              successRate: data.successRate,
              period: data.period,
              role: data.role,
            ),
          );
        },
      );
    } catch (e) {
      emit(EmployeeHomeError('Failed to load dashboard data'));
    }
  }
}
