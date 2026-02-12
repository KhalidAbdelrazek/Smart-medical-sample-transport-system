import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'home_state.dart';

/// Cubit for Home Tab
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial());

  /// Load home data with skeleton loading state
  Future<void> loadData() async {
    emit(HomeLoading());
    await _fetchData();
  }

  /// Refresh data silently (no skeleton, keeps current data visible)
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      await Future.delayed(const Duration(seconds: 2));
      emit(
        HomeLoaded(
          totalBagsProcessed: 24,
          totalSamplesProcessed: 18,
          carsDispatched: 8,
          currentShift: 'Morning (7:00 - 15:00)',
          employeeName: 'Ahmed Hassan',
        ),
      );
    } catch (e) {
      emit(HomeError('Failed to load data'));
    }
  }
}
