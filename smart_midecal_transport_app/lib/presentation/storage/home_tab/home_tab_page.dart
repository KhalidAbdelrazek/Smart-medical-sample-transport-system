import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/cubit/statistics_state.dart';
import 'package:smart_midecal_transport_app/presentation/employer/statistics_tab/ui/widgets/donut_chart_section.dart';

// Update imports to match your project structure
import 'ui/cubit/home_cubit.dart';
import 'ui/cubit/home_state.dart';
import 'ui/widgets/home_skeleton.dart';
import 'ui/widgets/stats_card.dart';

class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage>
    with AutomaticKeepAliveClientMixin {
  late HomeCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<HomeCubit>()..loadData();
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
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
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

  Widget _buildContent(BuildContext context, HomeState state) {
    if (state is HomeLoading || state is HomeInitial) {
      return const StorageHomeSkeleton(key: ValueKey('skeleton'));
    }

    if (state is HomeError) {
      return _ErrorBody(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => context.read<HomeCubit>().loadData(),
      );
    }

    if (state is HomeLoaded) {
      return _DashboardContent(key: const ValueKey('loaded'), state: state);
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

// ─── Dashboard content ────────────────────────────────────────────────────

class _DashboardContent extends StatelessWidget {
  final HomeLoaded state;

  const _DashboardContent({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
      children: [
        // // ── Header (Matching Admin/Doctor Style) ───────────────────────
        // _DashboardHeader(
        //   employeeName: state.employeeName,
        //   shift: state.currentShift,
        //   theme: theme,
        // ),
        // SizedBox(height: 24.h),

        // ── Activity Cards Section ─────────────────────────────────────
        _SectionLabel(
          icon: Icons.bar_chart_rounded,
          title: 'employee.storage_activity'.tr(),
          color: const Color(0xFF10B981),
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
            StatsCard(
              icon: Icons.analytics_rounded,
              color: AppColors.info,
              label: 'employee.total_actions'.tr(),
              value: state.totalactions.toString(),
            ),
            StatsCard(
              icon: Icons.local_shipping_rounded,
              color: AppColors.success,
              label: 'employee.cars_dispatched'.tr(),
              value: state.cardispatch.toString(),
            ),
            StatsCard(
              icon: Icons.add_box_rounded,
              color: const Color(0xFF10B981),
              label: 'employee.sample_added_to_car'.tr(),
              value: state.sampleaddedtocar.toString(),
            ),
            StatsCard(
              icon: Icons.indeterminate_check_box_rounded,
              color: AppColors.warning,
              label: 'employee.sample_removed_from_car'.tr(),
              value: state.sampleremovedfromcar.toString(),
            ),
          ],
        ),
        SizedBox(height: 12.h),

        Row(
          children: [
            Expanded(
              child: StatsCard(
                icon: Icons.sync_alt_rounded,
                color: const Color(0xFF8B5CF6),
                label: 'employee.transport_request_update'.tr(),
                value: state.transportrequestupdate.toString(),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: StatsCard(
                icon: Icons.more_horiz_rounded,
                color: AppColors.labelColor,
                label: 'employee.other'.tr(),
                value: state.other.toString(),
              ),
            ),
          ],
        ),
        SizedBox(height: 28.h),

        // ── Power BI Donut Chart Section ───────────────────────────────
        _SectionLabel(
          icon: Icons.pie_chart_rounded,
          title: 'home.today_stats'.tr(),
          color: AppColors.info,
          theme: theme,
        ),
        SizedBox(height: 14.h),

        DonutChartSection(
          title: 'employee.action_breakdown'.tr(),
          centerLabel: 'employee.actions'.tr(),
          total: state.totalactions,
          segments: [
            if (state.cardispatch > 0)
              ChartSegment(
                label: 'employee.dispatch'.tr(),
                value: state.cardispatch,
                percentage: (state.cardispatch / state.totalactions * 100),
              ),
            if (state.sampleaddedtocar > 0)
              ChartSegment(
                label: 'employee.added'.tr(),
                value: state.sampleaddedtocar,
                percentage: (state.sampleaddedtocar / state.totalactions * 100),
              ),
            if (state.sampleremovedfromcar > 0)
              ChartSegment(
                label: 'employee.removed'.tr(),
                value: state.sampleremovedfromcar,
                percentage:
                    (state.sampleremovedfromcar / state.totalactions * 100),
              ),
            if (state.transportrequestupdate > 0)
              ChartSegment(
                label: 'employee.updates'.tr(),
                value: state.transportrequestupdate,
                percentage:
                    (state.transportrequestupdate / state.totalactions * 100),
              ),
          ],
        ),
        SizedBox(height: 32.h),
      ],
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String employeeName;
  final String shift;
  final ThemeData theme;

  const _DashboardHeader({
    required this.employeeName,
    required this.shift,
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
                'Welcome, $employeeName',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                shift,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.labelColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
        // Role badge for Storage Employee
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warehouse_rounded, size: 14.sp, color: Colors.white),
              SizedBox(width: 5.w),
              Text(
                'STORAGE',
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

// ─── Error body ───────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorBody({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 48.sp,
            color: AppColors.error,
          ),
          SizedBox(height: 16.h),
          Text(message, style: theme.textTheme.bodyMedium),
          TextButton(onPressed: onRetry, child: Text('home.retry'.tr())),
        ],
      ),
    );
  }
}
