abstract class SignInState {
  const SignInState();
}

class SignInInitial extends SignInState {
  const SignInInitial();
}

class SignInParamsChanged extends SignInState {
  final bool rememberMe;
  final bool showPassword;
  final bool isEmployee;
  const SignInParamsChanged({
    required this.isEmployee,
    required this.rememberMe,
    required this.showPassword,
  });
}

class SignInLoading extends SignInState {}

class SignInSuccess extends SignInState {}

class SignInError extends SignInState {
  final String message;
  SignInError(this.message);
}
