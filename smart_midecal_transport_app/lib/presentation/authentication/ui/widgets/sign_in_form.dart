import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/common/custom_button.dart';
import 'package:smart_midecal_transport_app/core/common/custom_text_field.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/core/utils/validators.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/employee_login_view_model.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/employee_login_state.dart';

class SignInForm extends StatelessWidget {
  final EmployeeLoginViewModel cubit;
  const SignInForm({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EmployeeLoginViewModel, EmployeeLoginState>(
      bloc: cubit,
      builder: (context, state) {
        return Form(
          key: cubit.formKey,
          child: Column(
            children: [
              CustomTextField(
                label: "sign_in.email".tr(),
                controller: cubit.emailController,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email,
                validator: AppValidators.validateEmail,
              ),
              SizedBox(height: 12.h),
              CustomTextField(
                label: "sign_in.password".tr(),
                controller: cubit.passwordController,
                obscureText: cubit.obscurePassword,
                prefixIcon: Icons.lock,
                suffixIcon: cubit.obscurePassword
                    ? Icons.visibility_off
                    : Icons.visibility,
                onSuffixPressed: cubit.togglePasswordVisibility,
                validator: AppValidators.validatePassword,
              ),
              SizedBox(height: 10.h),
              CustomButton(
                body: Text(
                  "sign_in.sign_in_button".tr(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                color: AppColors.buttonColor,
                height: 36.h,
                width: 295.w,
                onPressed: () {
                  cubit.signIn();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
