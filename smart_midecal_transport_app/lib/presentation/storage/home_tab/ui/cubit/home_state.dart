/// States for Home Tab
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int totalBagsProcessed;
  final int totalSamplesProcessed;
  final int carsDispatched;
  final String currentShift;
  final String employeeName;

  HomeLoaded({
    required this.totalBagsProcessed,
    required this.totalSamplesProcessed,
    required this.carsDispatched,
    required this.currentShift,
    required this.employeeName,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
