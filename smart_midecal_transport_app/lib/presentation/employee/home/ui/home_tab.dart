import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/cubit/statistics_state.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/widgets/donut_chart_section.dart';

// Import the new widgets to match the Admin structure
import 'cubit/employee_home_cubit.dart';
import 'cubit/employee_home_state.dart';
import 'widgets/employee_stats_card.dart'; // Ensure this matches DashboardStatsCard style
import 'widgets/home_skeleton.dart';

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

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<EmployeeHomeCubit, EmployeeHomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<EmployeeHomeCubit>().refresh(),
            color: AppColors.primaryLight,
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

  Widget _buildContent(BuildContext context, EmployeeHomeState state) {
    if (state is EmployeeHomeLoading || state is EmployeeHomeInitial) {
      return const EmployeeHomeSkeleton(key: ValueKey('skeleton'));
    }

    if (state is EmployeeHomeError) {
      // Using a structure similar to Admin's StatsErrorWidget
      return _ErrorBody(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => context.read<EmployeeHomeCubit>().loadData(),
      );
    }

    if (state is EmployeeHomeLoaded) {
      return _DashboardContent(key: const ValueKey('loaded'), state: state);
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

// ─── Dashboard content ────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final EmployeeHomeLoaded state;

  const _DashboardContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      children: [
        // ── Header (Admin Style) ──────────────────────────────────────────
        _DashboardHeader(period: state.period, isDark: isDark, theme: theme),
        SizedBox(height: 24.h),

        // ── Stats Section ────────────────────────────────────────────────
        _SectionLabel(
          icon: Icons.analytics_rounded,
          title: 'employee.dashboard_subtitle'.tr(),
          color: AppColors.primaryLight,
          theme: theme,
        ),
        SizedBox(height: 14.h),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 1.35,
          children: [
            EmployeeStatsCard(
              icon: Icons.assignment_rounded,
              color: AppColors.info,
              label: 'extra.total_requests'.tr(),
              value: state.totalRequests.toString(),
            ),
            EmployeeStatsCard(
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
              label: 'extra.successful'.tr(),
              value: state.successfulRequests.toString(),
            ),
            EmployeeStatsCard(
              icon: Icons.cancel_rounded,
              color: AppColors.error,
              label: 'my_requests.status_cancelled'.tr(),
              value: state.cancelledRequests.toString(),
            ),
            EmployeeStatsCard(
              icon: Icons.do_not_disturb_on_rounded,
              color: AppColors.warning,
              label: 'extra.failed'.tr(),
              value: state.failedRequests.toString(),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        // Bottom row for specific KPIs
        Row(
          children: [
            Expanded(
              child: EmployeeStatsCard(
                icon: Icons.pending_actions_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'my_requests.status_pending'.tr(),
                value: state.pendingRequests.toString(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: EmployeeStatsCard(
                icon: Icons.trending_up_rounded,
                color: AppColors.success,
                label: 'extra.success_rate'.tr(),
                value: '${state.successRate.toStringAsFixed(1)}%',
              ),
            ),
          ],
        ),
        SizedBox(height: 24.h),

        // ── New Donut Chart Section ─────────────────────────────────────
        _SectionLabel(
          icon: Icons.pie_chart_rounded,
          title: 'employee.dashboard_title'.tr(),
          color: AppColors.secondary,
          theme: theme,
        ),
        SizedBox(height: 14.h),

        DonutChartSection(
          title: 'extra.request_breakdown'.tr(),
          centerLabel: 'nav.requests'.tr(),
          total: state.totalRequests,
          // Convert your basic state data into the ChartSegment list required by the widget
          segments: [
            ChartSegment(
              labelKey: 'extra.successful'.tr(),
              value: state.successfulRequests,
              percentage: state.totalRequests > 0
                  ? (state.successfulRequests / state.totalRequests * 100)
                  : 0,
            ),
            ChartSegment(
              labelKey: 'my_requests.status_pending'.tr(),
              value: state.pendingRequests,
              percentage: state.totalRequests > 0
                  ? (state.pendingRequests / state.totalRequests * 100)
                  : 0,
            ),
            ChartSegment(
              labelKey: 'my_requests.status_cancelled'.tr(),
              value: state.cancelledRequests,
              percentage: state.totalRequests > 0
                  ? (state.cancelledRequests / state.totalRequests * 100)
                  : 0,
            ),
            ChartSegment(
              labelKey: 'extra.failed'.tr(),
              value: state.failedRequests,
              percentage: state.totalRequests > 0
                  ? (state.failedRequests / state.totalRequests * 100)
                  : 0,
            ),
          ],
        ),
        SizedBox(height: 32.h),
      ],
    );
  }
}

// ─── Refactored Header (Admin Style) ──────────────────────────────────────

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
              Text(
                'employee.dashboard_title'.tr(),
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
                    color: AppColors.labelColor,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Role badge - Kept "Doctor" for this specific tab
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, AppColors.secondary],
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
              Icon(
                Icons.medical_services_rounded,
                size: 14.sp,
                color: Colors.white,
              ),
              SizedBox(width: 5.w),
              Text(
                'extra.doctor'.tr(),
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

// ─── Error body (Simplified) ──────────────────────────────────────────────
class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 48.sp),
          SizedBox(height: 16.h),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: onRetry, child: Text('employee.retry'.tr())),
        ],
      ),
    );
  }
}
