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

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> with SingleTickerProviderStateMixin {
  final signInCubit = getIt<SignInCubit>();
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

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

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
      create: (_) => signInCubit,
      child: BlocListener<SignInCubit, SignInState>(
        listener: (context, state) {
          if (state is SignInLoading) {
            DialogUtils.showLoading(context: context);
          } else if (state is SignInSuccess) {
            DialogUtils.hideLoading(context);
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
                              onPressed: () => localeProvider.toggleLocale(context),
                              icon: Icon(Icons.language, color: theme.iconTheme.color),
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
                        "sign_in.app_title".tr(),
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontSize: 26.sp,
                          color: theme.primaryColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        "sign_in.subtitle".tr(),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 40.h),
                      
                      // Modern Card Container
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(24.r),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withOpacity(0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            RoleSelector(cubit: signInCubit),
                            SizedBox(height: 32.h),
                            SignInForm(cubit: signInCubit),
                          ],
                        ),
                      ),
                      
                      SizedBox(height: 20.h),
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
