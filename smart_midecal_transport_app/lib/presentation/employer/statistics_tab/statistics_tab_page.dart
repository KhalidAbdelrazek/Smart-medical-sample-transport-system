import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/statistics_cubit.dart';
import 'cubit/statistics_state.dart';
import 'widgets/dashboard_stats_card.dart';
import 'widgets/blood_type_chart.dart';
import 'widgets/request_summary_card.dart';

/// Statistics Tab Page - Dashboard view for employer
/// Skeleton only shows on first load, not on pull-to-refresh
class StatisticsTabPage extends StatefulWidget {
  const StatisticsTabPage({super.key});

  @override
  State<StatisticsTabPage> createState() => _StatisticsTabPageState();
}

class _StatisticsTabPageState extends State<StatisticsTabPage>
    with AutomaticKeepAliveClientMixin {
  late StatisticsCubit _cubit;

  @override
  bool get wantKeepAlive => true; // Keep this tab alive

  @override
  void initState() {
    super.initState();
    _cubit = StatisticsCubit()..loadData();
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
      child: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<StatisticsCubit>().refresh(),
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
    StatisticsState state,
    ThemeData theme,
  ) {
    if (state is StatisticsLoading || state is StatisticsInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is StatisticsError) {
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
              onPressed: () => context.read<StatisticsCubit>().loadData(),
              child: Text('employer.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is StatisticsLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Welcome header
          Text(
            'employer.statistics_title'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'employer.statistics_subtitle'.tr(),
            style: theme.textTheme.bodySmall,
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
              DashboardStatsCard(
                icon: Icons.bloodtype_rounded,
                color: AppColors.error,
                label: 'employer.total_blood_bags'.tr(),
                value: state.totalBloodBagsRequested.toString(),
                subtitle: 'employer.requested'.tr(),
              ),
              DashboardStatsCard(
                icon: Icons.science_rounded,
                color: AppColors.info,
                label: 'employer.total_samples'.tr(),
                value: state.totalSamplesRequested.toString(),
                subtitle: 'employer.requested'.tr(),
              ),
              DashboardStatsCard(
                icon: Icons.local_shipping_rounded,
                color: AppColors.success,
                label: 'employer.cars_dispatched'.tr(),
                value: state.carsDispatched.toString(),
              ),
              DashboardStatsCard(
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                label: 'employer.pending_requests'.tr(),
                value: state.pendingRequests.toString(),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Blood type chart
          BloodTypeChart(
            bloodBagsByType: state.bloodBagsByType,
            title: 'employer.blood_bags_by_type'.tr(),
          ),
          SizedBox(height: 16.h),

          // Request summary
          RequestSummaryCard(
            title: 'employer.request_overview'.tr(),
            pendingCount: state.pendingRequests,
            completedCount: state.completedRequests,
            pendingLabel: 'employer.pending'.tr(),
            completedLabel: 'employer.completed'.tr(),
          ),
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
}
