import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../../cubit/employee_profile_cubit.dart';
import '../../cubit/employee_profile_state.dart';
import '../widgets/employee_profile_header.dart';
import '../widgets/employee_info_card.dart';
import '../widgets/employee_settings_section.dart';

/// Employee Profile Tab Page
/// Skeleton only shows on first load, not on pull-to-refresh
class EmployeeProfileTabPage extends StatefulWidget {
  const EmployeeProfileTabPage({super.key});

  @override
  State<EmployeeProfileTabPage> createState() => _EmployeeProfileTabPageState();
}

class _EmployeeProfileTabPageState extends State<EmployeeProfileTabPage>
    with AutomaticKeepAliveClientMixin {
  late EmployeeProfileCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = EmployeeProfileCubit()..loadData();
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
      child: BlocBuilder<EmployeeProfileCubit, EmployeeProfileState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => _cubit.refresh(),
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
    EmployeeProfileState state,
    ThemeData theme,
  ) {
    if (state is EmployeeProfileLoading || state is EmployeeProfileInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is EmployeeProfileError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(state.message),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _cubit.loadData(),
              child: Text('employee.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is EmployeeProfileLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Profile header
          EmployeeProfileHeader(name: state.name, role: state.role),
          SizedBox(height: 20.h),

          // Employee info card
          EmployeeInfoCard(
            title: 'employee.employee_info'.tr(),
            items: [
              EmployeeInfoItem(
                icon: Icons.badge_rounded,
                label: 'employee.employee_id'.tr(),
                value: state.employeeId,
              ),
              EmployeeInfoItem(
                icon: Icons.business_rounded,
                label: 'employee.department'.tr(),
                value: state.department,
              ),
              EmployeeInfoItem(
                icon: Icons.email_rounded,
                label: 'employee.email'.tr(),
                value: state.email,
              ),
              EmployeeInfoItem(
                icon: Icons.schedule_rounded,
                label: 'employee.shift'.tr(),
                value: state.shift,
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Settings section
          const EmployeeSettingsSection(),
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
        _shimmerBox(double.infinity, 200.h, isDark),
        SizedBox(height: 20.h),
        _shimmerBox(double.infinity, 260.h, isDark),
        SizedBox(height: 20.h),
        _shimmerBox(double.infinity, 200.h, isDark),
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
            borderRadius: BorderRadius.circular(20.r),
          ),
        );
      },
    );
  }
}
