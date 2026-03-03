import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Entity/login_admin_rb.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/Domain/Repository/auth_repository.dart';
import 'package:smart_midecal_transport_app/core/utils/shared_pref_services.dart';
import 'admin_login_state.dart';

@injectable
class AdminLoginViewModel extends Cubit<AdminLoginState> {
  final AuthRepository authRepository;
  AdminLoginViewModel(this.authRepository) : super(const AdminLoginInitial());

  bool rememberMe = false;
  bool obscurePassword = true;

  final formKey = GlobalKey<FormState>();
  final idController = TextEditingController(text: "admin@bioroute.com");
  final passwordController = TextEditingController(text: "AaAa112233_");

  void togglePasswordVisibility() {
    obscurePassword = !obscurePassword;
    _emitParamsChanged();
  }

  void toggleRememberMe() {
    rememberMe = !rememberMe;
    _emitParamsChanged();
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

    emit(AdminLoginLoading());

    final result = await authRepository.loginAdmin(
      LoginAdminRequestBodyEntity(
        email: idController.text
            .trim(), // Using idController as email in the entity
        password: passwordController.text,
      ),
    );

    result.fold((failure) => emit(AdminLoginError(failure.errorMessage)), (
      response,
    ) async {
      if (response.data?.access != null && response.data?.refresh != null) {
        await SharedPrefService.instance.saveTokens(
          response.data!.access!,
          response.data!.refresh!,
        );
        emit(AdminLoginSuccess());
      } else {
        emit(AdminLoginError(response.message ?? "Login failed"));
      }
    });
  }

  void _emitParamsChanged() {
    emit(
      AdminLoginParamsChanged(
        rememberMe: rememberMe,
        showPassword: obscurePassword,
      ),
    );
  }
}
