/// States for Employee Home Dashboard Tab
abstract class EmployeeHomeState {}

class EmployeeHomeInitial extends EmployeeHomeState {}

class EmployeeHomeLoading extends EmployeeHomeState {}

class EmployeeHomeLoaded extends EmployeeHomeState {
  final int totalBloodBagsRequested;
  final int totalSamplesRequested;
  final int todayBloodBags;
  final int todaySamples;
  final int pendingRequests;
  final int completedRequests;
  final Map<String, int> bloodBagsByType;

  EmployeeHomeLoaded({
    required this.totalBloodBagsRequested,
    required this.totalSamplesRequested,
    required this.todayBloodBags,
    required this.todaySamples,
    required this.pendingRequests,
    required this.completedRequests,
    required this.bloodBagsByType,
  });
}

class EmployeeHomeError extends EmployeeHomeState {
  final String message;
  EmployeeHomeError(this.message);
}