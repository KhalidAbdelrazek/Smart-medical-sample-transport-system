import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/domain/entities/admin_stats_entity.dart';

// ─── Chart data point model ────────────────────────────────────────────────

class ChartSegment {
  /// Translation key — resolved to a display string in the UI via .tr(),
  /// never translated inside the cubit so language switches work correctly.
  final String labelKey;
  final int value;
  final double percentage;

  const ChartSegment({
    required this.labelKey,
    required this.value,
    required this.percentage,
  });
}

// ─── States ────────────────────────────────────────────────────────────────

abstract class StatisticsState {}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final DoctorStatsEntity doctors;
  final StorageStatsEntity storage;
  final String period;
  final String selectedFilter;

  // Pre-computed chart segments (ViewModel responsibility)
  final List<ChartSegment> doctorSegments;
  final List<ChartSegment> storageSegments;

  StatisticsLoaded({
    required this.doctors,
    required this.storage,
    required this.period,
    required this.selectedFilter,
    required this.doctorSegments,
    required this.storageSegments,
  });
}

class StatisticsTokenExpired extends StatisticsState {}

class StatisticsError extends StatisticsState {
  final String message;
  final bool isNetwork;

  StatisticsError({required this.message, this.isNetwork = false});
}