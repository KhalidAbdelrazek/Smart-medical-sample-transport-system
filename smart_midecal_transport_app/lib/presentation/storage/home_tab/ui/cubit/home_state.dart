/// States for Home Tab
abstract class HomeState {}

class HomeInitial extends HomeState {}

class HomeLoading extends HomeState {}

class HomeLoaded extends HomeState {
  final int totalactions;
  final int cardispatch;
  final int sampleaddedtocar;
  final int sampleremovedfromcar;
  final int transportrequestupdate;
  final double other;

  final String period;
  final String role;

  /// UI-only fields (not from backend entity)
  // final String employeeName;
  // final String currentShift;

  HomeLoaded({
    required this.totalactions,
    required this.cardispatch,
    required this.sampleaddedtocar,
    required this.sampleremovedfromcar,
    required this.transportrequestupdate,
    required this.other,
    required this.period,
    required this.role,
    // required this.employeeName,
    // required this.currentShift,
  });
}

class HomeError extends HomeState {
  final String message;
  HomeError(this.message);
}
