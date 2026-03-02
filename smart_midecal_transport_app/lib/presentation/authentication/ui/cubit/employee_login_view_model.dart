import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_employee_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Repository/auth_repository.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'employee_login_state.dart';

@injectable
class EmployeeLoginViewModel extends Cubit<EmployeeLoginState> {
  final AuthRepository authRepository;
  EmployeeLoginViewModel(this.authRepository)
    : super(const EmployeeLoginInitial());

  bool rememberMe = false;
  bool obscurePassword = true;
  bool isEmployee = true;

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    _emitParamsChanged();
  }

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    _emitParamsChanged();
  }

  void setEmployee(bool value) {
    isEmployee = value;
    _emitParamsChanged();
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    emit(EmployeeLoginLoading());

    final result = await authRepository.loginEmployee(
      LoginEmployeeRequestBodyEntity(
        email: emailController.text.trim(),
        password: passwordController.text,
      ),
    );

    result.fold((failure) => emit(EmployeeLoginError(failure.errorMessage)), (
      response,
    ) async {
      if (response.access != null && response.refresh != null) {
        await SharedPrefService.instance.saveTokens(
          response.access!,
          response.refresh!,
        );
        emit(EmployeeLoginSuccess());
      } else {
        emit(EmployeeLoginError(response.message ?? "Login failed"));
      }
    });
  }

  void _emitParamsChanged() {
    emit(
      EmployeeLoginParamsChanged(
        rememberMe: rememberMe,
        showPassword: obscurePassword,
        isEmployee: isEmployee,
      ),
    );
  }
}
