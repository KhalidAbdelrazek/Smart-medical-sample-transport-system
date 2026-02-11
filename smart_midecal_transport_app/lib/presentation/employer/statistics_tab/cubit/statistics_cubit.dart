import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'statistics_state.dart';

/// Cubit for Statistics Tab
/// - loadData(): Shows skeleton (initial load)
/// - refresh(): Silent refresh (no skeleton)
/// All statistics calculations and data preparation happen here (ViewModel logic)
@injectable
class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit() : super(StatisticsInitial());

  /// Load statistics data with skeleton loading state
  Future<void> loadData() async {
    emit(StatisticsLoading());
    await _fetchData();
  }

  /// Refresh data silently (no skeleton, keeps current data visible)
  Future<void> refresh() async {
    await loadData();
  }

  Future<void> _fetchData() async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(seconds: 2));

      // Generate dummy statistics data (ViewModel logic)
      final bloodBagsByType = _generateBloodBagsByType();
      final totalBags = _calculateTotalBags(bloodBagsByType);
      final pendingRequests = _generatePendingCount();
      final completedRequests = _generateCompletedCount();

      emit(
        StatisticsLoaded(
          totalBloodBagsRequested: totalBags,
          totalSamplesRequested: 156,
          pendingRequests: pendingRequests,
          completedRequests: completedRequests,
          bloodBagsByType: bloodBagsByType,
          carsDispatched: 42,
        ),
      );
    } catch (e) {
      emit(StatisticsError('Failed to load statistics'));
    }
  }

  /// Generate dummy blood bags data by blood type
  Map<String, int> _generateBloodBagsByType() {
    return {
      'A+': 45,
      'A-': 12,
      'B+': 38,
      'B-': 8,
      'AB+': 15,
      'AB-': 5,
      'O+': 52,
      'O-': 18,
    };
  }

  /// Calculate total blood bags from type map
  int _calculateTotalBags(Map<String, int> byType) {
    return byType.values.fold(0, (sum, count) => sum + count);
  }

  /// Generate pending requests count
  int _generatePendingCount() {
    return 23;
  }

  /// Generate completed requests count
  int _generateCompletedCount() {
    return 189;
  }
}
