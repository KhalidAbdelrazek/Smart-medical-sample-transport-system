/// States for Profile Tab
abstract class ProfileState {}

class ProfileInitial extends ProfileState {}

class ProfileLoading extends ProfileState {}

class ProfileLoaded extends ProfileState {
  final String employeeName;
  final String employeeId;
  final String department;
  final String role;
  final String shift;
  final int todayBagsProcessed;
  final int todaySamplesProcessed;
  final int todayCarsDispatched;

  ProfileLoaded({
    required this.employeeName,
    required this.employeeId,
    required this.department,
    required this.role,
    required this.shift,
    required this.todayBagsProcessed,
    required this.todaySamplesProcessed,
    required this.todayCarsDispatched,
  });
}

class ProfileError extends ProfileState {
  final String message;
  ProfileError(this.message);
}
