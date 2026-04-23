import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/storage/home_tab/ui/widgets/advanced_donut_chart.dart';
import 'package:smart_midecal_transport_app/presentation/employee/home/ui/widgets/employee_donut_chart.dart';

import 'cubit/employee_home_cubit.dart';
import 'cubit/employee_home_state.dart';
import 'widgets/employee_stats_card.dart';
import 'widgets/employee_request_chart.dart';
import 'widgets/employee_summary_card.dart';

/// Employee Home Dashboard Tab
/// Skeleton only shows on first load, not on pull-to-refresh
class EmployeeHomeTabPage extends StatefulWidget {
  const EmployeeHomeTabPage({super.key});

  @override
  State<EmployeeHomeTabPage> createState() => _EmployeeHomeTabPageState();
}

class _EmployeeHomeTabPageState extends State<EmployeeHomeTabPage>
    with AutomaticKeepAliveClientMixin {
  late EmployeeHomeCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<EmployeeHomeCubit>()..loadData();
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
      child: BlocBuilder<EmployeeHomeCubit, EmployeeHomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<EmployeeHomeCubit>().refresh(),
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
    EmployeeHomeState state,
    ThemeData theme,
  ) {
    if (state is EmployeeHomeLoading || state is EmployeeHomeInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is EmployeeHomeError) {
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
              onPressed: () => context.read<EmployeeHomeCubit>().loadData(),
              child: Text('employee.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is EmployeeHomeLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Welcome header
          Text(
            'employee.dashboard_title'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'employee.dashboard_subtitle'.tr(),
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 24.h),
            AdvancedDonutChart(
  data: {
    "pending": state.pendingRequests , 
    "cancelled": state.cancelledRequests ,
    "failed": state.failedRequests ,
    "success": state.successfulRequests,
  },
),
         
          SizedBox(height: 24.h),
          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.1,
            children: [
              EmployeeStatsCard(
                icon: Icons.bloodtype_rounded,
                color: AppColors.appBarColor,
                label: 'Total requests'.tr(),
                value: state.totalRequests.toString(),
                subtitle: 'Total'.tr(args: [state.totalRequests.toString()]),
              ),

              EmployeeStatsCard(
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                label: 'Pending requests'.tr(),
                value: state.pendingRequests.toString(),
                subtitle: 'Pending'.tr(
                  args: [state.pendingRequests.toString()],
                ),
              ),
              EmployeeStatsCard(
                icon: Icons.cancel,
                color: AppColors.error,
                label: 'Cancelled requests'.tr(),
                value: state.cancelledRequests.toString(),
                subtitle: 'Cancelled'.tr(
                  args: [state.cancelledRequests.toString()],
                ),
              ),
              EmployeeStatsCard(
                icon: Icons.error_outline,
                color: AppColors.bottomBarDarkColor,
                label: 'Failed requests'.tr(),
                value: state.failedRequests.toString(),
                subtitle: 'Failed'.tr(args: [state.failedRequests.toString()]),
              ),
              EmployeeStatsCard(
                icon: Icons.error_outline,
                color: AppColors.success,
                label: 'successful requests'.tr(),
                value: state.successfulRequests.toString(),
                subtitle: 'successful'.tr(
                  args: [state.successfulRequests.toString()],
                ),
              ),
              EmployeeStatsCard(
                icon: Icons.error_outline,
                color: AppColors.success,
                label: 'Success Rate'.tr(),
                value: state.successRate.toString(),
                subtitle: 'Success Rate'.tr(
                  args: [state.successRate.toString()],
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Blood bags vs samples chart
          // EmployeeRequestChart(
          //   bloodBags: state.totalBloodBagsRequested,
          //   bloodSamples: state.totalSamplesRequested,
          //   bloodBagsLabel: 'employee.blood_bags'.tr(),
          //   samplesLabel: 'employee.blood_samples'.tr(),
          //   title: 'employee.requests_distribution'.tr(),
          // ),
          SizedBox(height: 16.h),

          // Request summary
          // EmployeeSummaryCard(
          //   title: 'employee.request_overview'.tr(),
          //   pendingCount: state.pendingRequests,
          //   completedCount: state.completedRequests,
          //   pendingLabel: 'employee.pending'.tr(),
          //   completedLabel: 'employee.completed'.tr(),
          // ),
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
        _shimmerBox(200.w, 24.h, isDark),
        SizedBox(height: 8.h),
        _shimmerBox(150.w, 16.h, isDark),
        SizedBox(height: 24.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.1,
          children: List.generate(
            4,
            (_) => _shimmerBox(double.infinity, double.infinity, isDark),
          ),
        ),
        SizedBox(height: 24.h),
        _shimmerBox(double.infinity, 160.h, isDark),
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
}
