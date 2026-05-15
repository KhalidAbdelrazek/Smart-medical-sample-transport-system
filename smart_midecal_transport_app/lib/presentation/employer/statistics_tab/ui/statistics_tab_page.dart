import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/statistics_cubit.dart';
import 'cubit/statistics_state.dart';
import 'widgets/dashboard_stats_card.dart';
import 'widgets/donut_chart_section.dart';
import 'widgets/stats_error_widget.dart';
import 'widgets/stats_filter_bar.dart';
import 'widgets/stats_skeleton.dart';

/// Admin Statistics Dashboard — Power BI style
/// Skeleton only shows on first load and filter changes.
class StatisticsTabPage extends StatefulWidget {
  const StatisticsTabPage({super.key});

  @override
  State<StatisticsTabPage> createState() => _StatisticsTabPageState();
}

class _StatisticsTabPageState extends State<StatisticsTabPage>
    with AutomaticKeepAliveClientMixin {
  late final StatisticsCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<StatisticsCubit>()..loadData();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<StatisticsCubit, StatisticsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<StatisticsCubit>().refresh(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _buildContent(context, state),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StatisticsState state) {
    if (state is StatisticsLoading || state is StatisticsInitial) {
      return IgnorePointer(
        key: const ValueKey('skeleton'),
        child: const StatisticsSkeletonScreen(),
      );
    }

    if (state is StatisticsTokenExpired) {
      return StatsErrorWidget(
        key: const ValueKey('token_expired'),
        message: 'extra.session_expired_long'.tr(),
        isTokenExpired: true,
        onRetry: () => context.read<StatisticsCubit>().loadData(),
        // TODO: wire onLogout to your auth cubit logout method
        onLogout: () => context.read<StatisticsCubit>().loadData(),
      );
    }

    if (state is StatisticsError) {
      return StatsErrorWidget(
        key: const ValueKey('error'),
        message: state.message,
        isNetwork: state.isNetwork,
        onRetry: () => context.read<StatisticsCubit>().loadData(),
      );
    }

    if (state is StatisticsLoaded) {
      return _DashboardContent(key: const ValueKey('loaded'), state: state);
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

// ─── Dashboard content ────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final StatisticsLoaded state;

  const _DashboardContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final d = state.doctors;
    final s = state.storage;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      children: [
        // ── Header ───────────────────────────────────────────────────────
        _DashboardHeader(
          period: state.period,
          isDark: isDark,
          theme: theme,
        ),
        SizedBox(height: 20.h),

        // ── Filter Bar ───────────────────────────────────────────────────
        StatsFilterBar(
          selectedFilter: state.selectedFilter,
          onFilterChanged: (f) =>
              context.read<StatisticsCubit>().changeFilter(f),
        ),
        SizedBox(height: 24.h),

        // ── Doctor Section ───────────────────────────────────────────────
        _SectionLabel(
          icon: Icons.medical_services_rounded,
          title: 'extra.doctor_requests'.tr(),
          color: AppColors.info,
          theme: theme,
        ),
        SizedBox(height: 14.h),

        // Doctor stats cards (2-column grid)
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: [
            DashboardStatsCard(
              icon: Icons.assignment_rounded,
              color: AppColors.info,
              label: 'extra.total_requests'.tr(),
              value: '${d.totalRequests ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'extra.successful'.tr(),
              value: '${d.successful ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              label: 'extra.failed'.tr(),
              value: '${d.failed ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.do_not_disturb_on_rounded,
              color: AppColors.warning,
              label: 'my_requests.status_cancelled'.tr(),
              value: '${d.cancelled ?? 0}',
            ),
          ],
        ),

        // Pending card (full width)
        SizedBox(height: 12.h),
        DashboardStatsCard(
          icon: Icons.pending_actions_rounded,
          color: const Color(0xFF8B5CF6),
          label: 'employer.pending_requests'.tr(),
          value: '${d.pending ?? 0}',
        ),
        SizedBox(height: 20.h),

        // Doctor donut chart
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: DonutChartSection(
            key: ValueKey('doctor_chart_${state.selectedFilter}'),
            title: 'extra.request_breakdown'.tr(),
            segments: state.doctorSegments,
            total: d.totalRequests ?? 0,
            centerLabel: 'nav.requests'.tr(),
          ),
        ),
        SizedBox(height: 28.h),

        // ── Storage Section ──────────────────────────────────────────────
        _SectionLabel(
          icon: Icons.warehouse_rounded,
          title: 'employee.storage_activity'.tr(),
          color: const Color(0xFF10B981),
          theme: theme,
        ),
        SizedBox(height: 14.h),

        // Storage stats cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: [
            DashboardStatsCard(
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF10B981),
              label: 'employee.total_actions'.tr(),
              value: '${s.totalActions ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.local_shipping_rounded,
              color: AppColors.info,
              label: 'extra.car_dispatch'.tr(),
              value: '${s.carDispatch ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.add_box_rounded,
              color: AppColors.success,
              label: 'extra.sample_added'.tr(),
              value: '${s.sampleAddedToCar ?? 0}',
            ),
            DashboardStatsCard(
              icon: Icons.indeterminate_check_box_rounded,
              color: AppColors.warning,
              label: 'extra.sample_removed'.tr(),
              value: '${s.sampleRemovedFromCar ?? 0}',
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Transport updates + other in a row
        Row(
          children: [
            Expanded(
              child: DashboardStatsCard(
                icon: Icons.sync_alt_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'extra.transport_updates'.tr(),
                value: '${s.transportRequestUpdate ?? 0}',
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: DashboardStatsCard(
                icon: Icons.more_horiz_rounded,
                color: AppColors.labelColor,
                label: 'extra.other_actions'.tr(),
                value: '${s.other ?? 0}',
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),

        // Storage donut chart
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: DonutChartSection(
            key: ValueKey('storage_chart_${state.selectedFilter}'),
            title: 'extra.activity_breakdown'.tr(),
            segments: state.storageSegments,
            total: s.totalActions ?? 0,
            centerLabel: 'employee.actions'.tr(),
          ),
        ),
        SizedBox(height: 32.h),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String period;
  final bool isDark;
  final ThemeData theme;

  const _DashboardHeader({
    required this.period,
    required this.isDark,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('extra.analytics_dashboard'.tr(),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20.sp,
                ),
              ),
              if (period.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(
                  period,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Role badge
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primaryLight,
                AppColors.secondary,
              ],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryLight.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded,
                  size: 14.sp, color: Colors.white),
              SizedBox(width: 5.w),
              Text('extra.admin'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Section label ────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final ThemeData theme;

  const _SectionLabel({
    required this.icon,
    required this.title,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: color),
        ),
        SizedBox(width: 10.w),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 15.sp,
          ),
        ),
      ],
    );
  }
}
