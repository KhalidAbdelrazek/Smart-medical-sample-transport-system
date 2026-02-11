/// States for Employee Profile
abstract class EmployeeProfileState {}

class EmployeeProfileInitial extends EmployeeProfileState {}

class EmployeeProfileLoading extends EmployeeProfileState {}

class EmployeeProfileLoaded extends EmployeeProfileState {
  final String name;
  final String role;
  final String employeeId;
  final String department;
  final String email;
  final String shift;
  final String joinDate;

  EmployeeProfileLoaded({
    required this.name,
    required this.role,
    required this.employeeId,
    required this.department,
    required this.email,
    required this.shift,
    required this.joinDate,
  });
}

class EmployeeProfileError extends EmployeeProfileState {
  final String message;
  EmployeeProfileError(this.message);
}
