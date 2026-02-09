/// States for Statistics Tab
abstract class StatisticsState {}

class StatisticsInitial extends StatisticsState {}

class StatisticsLoading extends StatisticsState {}

class StatisticsLoaded extends StatisticsState {
  final int totalBloodBagsRequested;
  final int totalSamplesRequested;
  final int pendingRequests;
  final int completedRequests;
  final Map<String, int> bloodBagsByType;
  final int carsDispatched;

  StatisticsLoaded({
    required this.totalBloodBagsRequested,
    required this.totalSamplesRequested,
    required this.pendingRequests,
    required this.completedRequests,
    required this.bloodBagsByType,
    required this.carsDispatched,
  });
}

class StatisticsError extends StatisticsState {
  final String message;
  StatisticsError(this.message);
}
