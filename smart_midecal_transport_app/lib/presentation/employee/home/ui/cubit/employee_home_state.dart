/// States for Employee Home Dashboard Tab
abstract class EmployeeHomeState {}

class EmployeeHomeInitial extends EmployeeHomeState {}

class EmployeeHomeLoading extends EmployeeHomeState {}

class EmployeeHomeLoaded extends EmployeeHomeState {
  final int totalRequests;
  final int successfulRequests;
  final int failedRequests;
  final int cancelledRequests;
  final int pendingRequests;
  final double successRate;
  final String period;
  final String role;

  EmployeeHomeLoaded({
    required this.totalRequests,
    required this.successfulRequests,
    required this.failedRequests,
    required this.cancelledRequests,
    required this.pendingRequests,
    required this.successRate,
    required this.period,
    required this.role,
  });
}

class EmployeeHomeError extends EmployeeHomeState {
  final String message;
  EmployeeHomeError(this.message);
}
