abstract class AdminLoginState {
  const AdminLoginState();
}

class AdminLoginInitial extends AdminLoginState {
  const AdminLoginInitial();
}

class AdminLoginParamsChanged extends AdminLoginState {
  final bool rememberMe;
  final bool showPassword;
  const AdminLoginParamsChanged({
    required this.rememberMe,
    required this.showPassword,
  });
}

class AdminLoginLoading extends AdminLoginState {}

class AdminLoginSuccess extends AdminLoginState {}

class AdminLoginError extends AdminLoginState {
  final String? message;
  AdminLoginError({this.message});
}
