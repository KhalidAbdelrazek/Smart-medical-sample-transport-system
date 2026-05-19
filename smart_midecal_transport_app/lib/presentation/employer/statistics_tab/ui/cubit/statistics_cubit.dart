import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/core/error/failures.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/repos/admin_stats_repository.dart';
import 'statistics_state.dart';

/// Filter options mapping (key → translation key)
/// The values are translation keys resolved at build time via .tr()
const Map<String, String> filterLabelKeys = {
  'week': 'statistics.filter_week',
  'month': 'statistics.filter_month',
  'year': 'statistics.filter_year',
  'all_time': 'statistics.filter_all_time',
};

/// StatisticsCubit — ViewModel for the Admin Statistics Dashboard
///
/// Responsibilities:
/// - Orchestrates API calls via [AdminStatsRepository]
/// - Manages loading / success / error / token-expired states
/// - Pre-computes chart segments and percentages (ViewModel logic)
/// - Manages active filter selection
@injectable
class StatisticsCubit extends Cubit<StatisticsState> {
  final AdminStatsRepository _repository;

  String _selectedFilter = 'month';
  String get selectedFilter => _selectedFilter;

  StatisticsCubit(this._repository) : super(StatisticsInitial());

  // ─── Public API ────────────────────────────────────────────────────────

  /// Initial load — shows skeleton loading UI
  Future<void> loadData({String? filter}) async {
    _selectedFilter = filter ?? _selectedFilter;
    emit(StatisticsLoading());
    await _fetchData();
  }

  /// Change filter and reload (also shows loading skeleton)
  Future<void> changeFilter(String filter) async {
    if (_selectedFilter == filter) return;
    _selectedFilter = filter;
    emit(StatisticsLoading());
    await _fetchData();
  }

  /// Silent refresh — re-fetches with current filter, shows loading again
  Future<void> refresh() async {
    emit(StatisticsLoading());
    await _fetchData();
  }

  // ─── Private ───────────────────────────────────────────────────────────

  Future<void> _fetchData() async {
    final result = await _repository.getStatistics(
      selectedPeriod: _selectedFilter,
    );

    result.fold(
      (failure) => _handleFailure(failure),
      (entity) => _handleSuccess(entity),
    );
  }

  void _handleFailure(Failures failure) {
    if (failure is TokenExpiredFailure) {
      emit(StatisticsTokenExpired());
      return;
    }

    emit(
      StatisticsError(
        message: failure.errorMessage,
        isNetwork: failure is NetworkError,
      ),
    );
  }

  void _handleSuccess(dynamic entity) {
    // Guard: entity must have data
    if (entity.data == null) {
      emit(StatisticsError(message: entity.message ?? 'No data available'));
      return;
    }

    final data = entity.data!;
    final doctors = data.doctors;
    final storage = data.storage;

    if (doctors == null || storage == null) {
      emit(StatisticsError(message: 'extra.incomplete_data'.tr()));
      return;
    }

    emit(
      StatisticsLoaded(
        doctors: doctors,
        storage: storage,
        period: data.period ?? '',
        selectedFilter: _selectedFilter,
        doctorSegments: _buildDoctorSegments(doctors),
        storageSegments: _buildStorageSegments(storage),
      ),
    );
  }

  // ─── Chart segment builders (ViewModel logic) ─────────────────────────

  List<ChartSegment> _buildDoctorSegments(DoctorStatsEntity d) {
    final total = d.totalRequests ?? 0;
    if (total == 0) return [];

    final items = [
      ('statistics.segment_successful'.tr(), d.successful ?? 0),
      ('statistics.segment_failed'.tr(), d.failed ?? 0),
      ('statistics.segment_cancelled'.tr(), d.cancelled ?? 0),
      ('statistics.segment_pending'.tr(), d.pending ?? 0),
    ];

    return items
        .where((e) => e.$2 > 0)
        .map(
          (e) => ChartSegment(
            label: e.$1,
            value: e.$2,
            percentage: _pct(e.$2, total),
          ),
        )
        .toList();
  }

  List<ChartSegment> _buildStorageSegments(StorageStatsEntity s) {
    final total = s.totalActions ?? 0;
    if (total == 0) return [];

    final items = [
      ('statistics.segment_car_dispatch'.tr(), s.carDispatch ?? 0),
      ('statistics.segment_sample_added'.tr(), s.sampleAddedToCar ?? 0),
      ('statistics.segment_sample_removed'.tr(), s.sampleRemovedFromCar ?? 0),
      ('statistics.segment_transport_updates'.tr(), s.transportRequestUpdate ?? 0),
      ('statistics.segment_other'.tr(), s.other ?? 0),
    ];

    return items
        .where((e) => e.$2 > 0)
        .map(
          (e) => ChartSegment(
            label: e.$1,
            value: e.$2,
            percentage: _pct(e.$2, total),
          ),
        )
        .toList();
  }

  double _pct(int value, int total) =>
      total == 0 ? 0 : double.parse(((value / total) * 100).toStringAsFixed(1));
}