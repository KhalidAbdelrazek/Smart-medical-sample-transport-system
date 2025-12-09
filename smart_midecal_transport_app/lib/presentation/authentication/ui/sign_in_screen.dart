import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/core/common/dialog_utils.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/provider/locale_provider.dart';
import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/sign_in_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/sign_in_state.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/widgets/role_selector.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/widgets/sign_in_form.dart';

class SignInScreen extends StatelessWidget {
   SignInScreen({super.key});
  final signInCubit = getIt<SignInCubit>();

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();

    return BlocProvider(
      create: (_) => signInCubit,
      child: BlocListener<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInLoading) {
            DialogUtils.showLoading(context: context);
          } else if(state is SignInSuccess) {
            DialogUtils.hideLoading(context);
          }
        },
        child: Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: () => themeProvider.toggleTheme(),
                          icon: Icon(
                            themeProvider.isDark
                                ? Icons.dark_mode
                                : Icons.light_mode,
                          ),
                        ),
                        IconButton(
                          onPressed: () => localeProvider.toggleLocale(context),
                          icon: const Icon(Icons.language),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                  Image.asset(AppAssets.appLogo, height: 90.h),
                  SizedBox(height: 20.h),
                  Text(
                    "sign_in.app_title".tr(),
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    "sign_in.subtitle".tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  SizedBox(height: 30.h),
                  Container(
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        RoleSelector(cubit: signInCubit),
                        SizedBox(height: 20.h),
                        SignInForm(cubit: signInCubit),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
