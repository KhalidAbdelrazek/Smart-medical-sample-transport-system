import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:smart_midecal_transport_app/core/assets/app_assets.dart';
import 'package:smart_midecal_transport_app/core/common/dialog_utils.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/provider/locale_provider.dart';
import 'package:smart_midecal_transport_app/core/provider/theme_provider.dart';
import 'package:smart_midecal_transport_app/core/routes/route_names.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/admin_login_view_model.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/cubit/admin_login_state.dart';
import 'package:smart_midecal_transport_app/presentation/authentication/ui/widgets/admin_sign_in_form.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen>
    with SingleTickerProviderStateMixin {
  final adminLoginViewModel = getIt<AdminLoginViewModel>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) => adminLoginViewModel,
      child: BlocListener<AdminLoginViewModel, AdminLoginState>(
        listener: (context, state) {
          if (state is AdminLoginLoading) {
            DialogUtils.showLoading(context: context);
          } else if (state is AdminLoginSuccess) {
            DialogUtils.hideLoading(context);
            // Navigate to Admin Dashboard (sharing root for now or separate)
            Navigator.pushReplacementNamed(
              context,
              RouteNames.employerMainScreen,
            );
          } else if (state is AdminLoginError) {
            DialogUtils.hideLoading(context);
            DialogUtils.showMessage(
              context: context,
              title: "sign_in.login_failed".tr(),
              message: state.message == 'Invalid email or password.'
                  ? "errors.invalid_credential".tr()
                  : state.message == 'Network error'
                  ? "errors.network_error".tr()
                  : "errors.unknown_error".tr(),
              posActionName: "sign_in.ok".tr(),
            );
          }
        },
        child: Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
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
                                color: theme.iconTheme.color,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  localeProvider.toggleLocale(context),
                              icon: Icon(
                                Icons.language,
                                color: theme.iconTheme.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Hero(
                        tag: 'app_logo',
                        child: Image.asset(AppAssets.appLogo, height: 100.h),
                      ),
                      SizedBox(height: 24.h),
                      Text(
                        "sign_in.admin_portal".tr(),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 26.sp,
                          color: theme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "sign_in.admin_portal_description".tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withValues(
                            alpha: 0.7,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40.h),

                      // Modern Card Container
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 32.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AdminSignInForm(cubit: adminLoginViewModel),
                          ],
                        ),
                      ),

                      SizedBox(height: 20.h),
                      TextButton(
                        onPressed: () => Navigator.pushReplacementNamed(
                          context,
                          RouteNames.register,
                        ),
                        child: Text(
                          "sign_in.switch_to_employee_login".tr(),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
