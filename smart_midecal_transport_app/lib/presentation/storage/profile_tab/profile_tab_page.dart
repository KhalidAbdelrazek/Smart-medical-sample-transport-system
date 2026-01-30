import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/profile_cubit.dart';
import 'cubit/profile_state.dart';
import 'widgets/profile_header.dart';
import 'widgets/info_card.dart';
import 'widgets/settings_section.dart';

/// Profile Tab Page - Cached with AutomaticKeepAliveClientMixin
/// Skeleton only shows on first load, not on pull-to-refresh
class ProfileTabPage extends StatefulWidget {
  const ProfileTabPage({super.key});

  @override
  State<ProfileTabPage> createState() => _ProfileTabPageState();
}

class _ProfileTabPageState extends State<ProfileTabPage>
    with AutomaticKeepAliveClientMixin {
  late ProfileCubit _cubit;

  @override
  bool get wantKeepAlive => true; // Keep this tab alive

  @override
  void initState() {
    super.initState();
    _cubit = ProfileCubit()..loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<ProfileCubit, ProfileState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<ProfileCubit>().refresh(),
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
    ProfileState state,
    ThemeData theme,
  ) {
    if (state is ProfileLoading || state is ProfileInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is ProfileError) {
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
              onPressed: () => context.read<ProfileCubit>().loadData(),
              child: Text('profile.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is ProfileLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Profile header
          Center(
            child: ProfileHeader(name: state.employeeName, role: state.role),
          ),
          SizedBox(height: 24.h),

          // Employee Info Card
          InfoCard(
            title: 'profile.employee_info'.tr(),
            items: [
              InfoItem(
                icon: Icons.badge_rounded,
                color: AppColors.primaryLight,
                label: 'profile.employee_id'.tr(),
                value: state.employeeId,
              ),
              InfoItem(
                icon: Icons.business_rounded,
                color: AppColors.info,
                label: 'profile.department'.tr(),
                value: state.department,
              ),
              InfoItem(
                icon: Icons.schedule_rounded,
                color: AppColors.success,
                label: 'profile.shift'.tr(),
                value: state.shift,
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Today's Stats Card
          InfoCard(
            title: 'profile.today_stats'.tr(),
            items: [
              InfoItem(
                icon: Icons.bloodtype_rounded,
                color: AppColors.error,
                label: 'profile.bags_processed'.tr(),
                value: state.todayBagsProcessed.toString(),
              ),
              InfoItem(
                icon: Icons.science_rounded,
                color: AppColors.info,
                label: 'profile.samples_processed'.tr(),
                value: state.todaySamplesProcessed.toString(),
              ),
              InfoItem(
                icon: Icons.local_shipping_rounded,
                color: AppColors.success,
                label: 'profile.cars_dispatched'.tr(),
                value: state.todayCarsDispatched.toString(),
              ),
            ],
          ),
          SizedBox(height: 16.h),

          // Settings Section
          const SettingsSection(),
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
        Center(child: _shimmerCircle(90.w, isDark)),
        SizedBox(height: 16.h),
        Center(child: _shimmerBox(150.w, 24.h, isDark)),
        SizedBox(height: 8.h),
        Center(child: _shimmerBox(100.w, 30.h, isDark)),
        SizedBox(height: 24.h),
        _shimmerBox(double.infinity, 180.h, isDark),
        SizedBox(height: 16.h),
        _shimmerBox(double.infinity, 180.h, isDark),
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
