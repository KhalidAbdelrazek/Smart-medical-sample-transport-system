import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'sign_in_state.dart';

@injectable
class SignInCubit extends Cubit<SignInState> {
  SignInCubit() : super(const SignInInitial());

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

  void signIn() {
    emit(SignInLoading());
    Future.delayed(const Duration(seconds: 1), () {
      emit(SignInSuccess());
    });
  }

  void _emitParamsChanged() {
    emit(SignInParamsChanged(
      rememberMe: rememberMe,
      showPassword: obscurePassword,
      isEmployee: isEmployee,
    ));
  }
}
