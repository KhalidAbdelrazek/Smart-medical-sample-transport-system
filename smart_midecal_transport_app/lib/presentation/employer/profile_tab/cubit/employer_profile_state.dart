/// States for Employer Profile Tab
abstract class EmployerProfileState {}

class EmployerProfileInitial extends EmployerProfileState {}

class EmployerProfileLoading extends EmployerProfileState {}

class EmployerProfileLoaded extends EmployerProfileState {
  final String employerId;
  final String employerName;
  final String mainRole;
  final String department;
  final String email;
  final String joinDate;

  EmployerProfileLoaded({
    required this.employerId,
    required this.employerName,
    required this.mainRole,
    required this.department,
    required this.email,
    required this.joinDate,
  });
}

class EmployerProfileError extends EmployerProfileState {
  final String message;
  EmployerProfileError(this.message);
}
