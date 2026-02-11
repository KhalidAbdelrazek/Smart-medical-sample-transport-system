import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/employer_profile_cubit.dart';
import 'cubit/employer_profile_state.dart';
import 'widgets/employer_profile_header.dart';
import 'widgets/employer_info_card.dart';
import 'widgets/employer_settings_section.dart';

/// Employer Profile Tab Page
/// Skeleton only shows on first load, not on pull-to-refresh
class EmployerProfileTabPage extends StatefulWidget {
  const EmployerProfileTabPage({super.key});

  @override
  State<EmployerProfileTabPage> createState() => _EmployerProfileTabPageState();
}

class _EmployerProfileTabPageState extends State<EmployerProfileTabPage>
    with AutomaticKeepAliveClientMixin {
  late EmployerProfileCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<EmployerProfileCubit>()..loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EmployerProfileCubit, EmployerProfileState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<EmployerProfileCubit>().refresh(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(context, state, theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    EmployerProfileState state,
    ThemeData theme,
  ) {
    if (state is EmployerProfileLoading || state is EmployerProfileInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is EmployerProfileError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(state.message, style: theme.textTheme.bodyLarge),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => context.read<EmployerProfileCubit>().loadData(),
              child: Text('employer.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is EmployerProfileLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Profile header
          Center(
            child: EmployerProfileHeader(
              name: state.employerName,
              role: state.mainRole,
            ),
          ),
          SizedBox(height: 24.h),

          // Employer Info Card
          EmployerInfoCard(
            title: 'employer.employer_info'.tr(),
            items: [
              EmployerInfoItem(
                icon: Icons.badge_rounded,
                color: AppColors.primaryLight,
                label: 'employer.employer_id'.tr(),
                value: state.employerId,
              ),
              EmployerInfoItem(
                icon: Icons.business_rounded,
                color: AppColors.info,
                label: 'employer.department'.tr(),
                value: state.department,
              ),
              EmployerInfoItem(
                icon: Icons.email_rounded,
                color: AppColors.secondary,
                label: 'employer.email'.tr(),
                value: state.email,
              ),
              EmployerInfoItem(
                icon: Icons.calendar_today_rounded,
                color: AppColors.success,
                label: 'employer.join_date'.tr(),
                value: state.joinDate,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Settings Section
          const EmployerSettingsSection(),
          SizedBox(height: 32.h),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildLoadingSkeleton(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        Center(child: _shimmerCircle(100.w, isDark)),
        SizedBox(height: 16.h),
        Center(child: _shimmerBox(150.w, 24.h, isDark)),
        SizedBox(height: 8.h),
        Center(child: _shimmerBox(100.w, 30.h, isDark)),
        SizedBox(height: 24.h),
        _shimmerBox(double.infinity, 200.h, isDark),
        SizedBox(height: 16.h),
        _shimmerBox(double.infinity, 120.h, isDark),
      ],
    );
  }

  Widget _shimmerBox(double width, double height, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.grey).withValues(
              alpha: value,
            ),
            borderRadius: BorderRadius.circular(16.r),
          ),
        );
      },
    );
  }

  Widget _shimmerCircle(double size, bool isDark) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 0.6),
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.grey).withValues(
              alpha: value,
            ),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
