abstract class EmployeeLoginState {
  const EmployeeLoginState();
}

class EmployeeLoginInitial extends EmployeeLoginState {
  const EmployeeLoginInitial();
}

class EmployeeLoginParamsChanged extends EmployeeLoginState {
  final bool rememberMe;
  final bool showPassword;
  final bool isEmployee;
  const EmployeeLoginParamsChanged({
    required this.isEmployee,
    required this.rememberMe,
    required this.showPassword,
  });
}

class EmployeeLoginLoading extends EmployeeLoginState {}

class EmployeeLoginSuccess extends EmployeeLoginState {}

class EmployeeLoginError extends EmployeeLoginState {
  final String message;
  EmployeeLoginError(this.message);
}
