import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/domain/repos/static_storage_repo.dart';

import 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  final StorageStatisticsRepo repo;

  HomeCubit(this.repo) : super(HomeInitial());

  /// First load (shows skeleton)
  Future<void> loadData() async {
    emit(HomeLoading());
    await _fetchData();
  }

  /// Silent refresh (no skeleton)
  Future<void> refresh() async {
    await _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final result = await repo.getStatistics();

      result.fold(
        (failure) =>
            emit(HomeError("Failed to load data: ${failure.toString()}")),
        (data) => emit(
          HomeLoaded(
            totalactions: data.totalactions,
            cardispatch: data.cardispatch,
            sampleaddedtocar: data.sampleaddedtocar,
            sampleremovedfromcar: data.sampleremovedfromcar,
            transportrequestupdate: data.transportrequestupdate,
            other: data.other,
            period: data.period,
            role: data.role,

            // UI-only (can later come from profile module)
            // employeeName: "Ahmed Hassan",
            // currentShift: "Morning (7:00 - 15:00)",
          ),
        ),
      );
    } catch (e) {
      emit(HomeError("Failed to load data: ${e.toString()}"));
    }
  }
}
