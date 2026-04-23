import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'ui/cubit/home_cubit.dart';
import 'ui/cubit/home_state.dart';
import 'ui/widgets/stats_card.dart';
import 'ui/widgets/welcome_header.dart';

/// Home Tab Page - Cached with AutomaticKeepAliveClientMixin
/// Skeleton only shows on first load, not on pull-to-refresh
class HomeTabPage extends StatefulWidget {
  const HomeTabPage({super.key});

  @override
  State<HomeTabPage> createState() => _HomeTabPageState();
}

class _HomeTabPageState extends State<HomeTabPage>
    with AutomaticKeepAliveClientMixin {
  late HomeCubit _cubit;

  @override
  bool get wantKeepAlive => true; // Keep this tab alive

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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final theme = Theme.of(context);

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildContent(context, state, theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, HomeState state, ThemeData theme) {
    if (state is HomeLoading || state is HomeInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is HomeError) {
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
              onPressed: () => context.read<HomeCubit>().loadData(),
              child: Text('home.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is HomeLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Welcome header
          WelcomeHeader(
            employeeName: state.employeeName,
            shift: state.currentShift,
          ),
          SizedBox(height: 24.h),

          // Today's stats title
          Text(
            'home.today_stats'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),

          // Stats grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.1,
            children: [
              StatsCard(
                icon: Icons.bloodtype_rounded,
                color: AppColors.error,
                label: 'home.blood_bags'.tr(),
                value: state.totalBagsProcessed.toString(),
              ),
              StatsCard(
                icon: Icons.science_rounded,
                color: AppColors.info,
                label: 'home.samples'.tr(),
                value: state.totalSamplesProcessed.toString(),
              ),
              StatsCard(
                icon: Icons.local_shipping_rounded,
                color: AppColors.success,
                label: 'home.cars_dispatched'.tr(),
                value: state.carsDispatched.toString(),
              ),
              StatsCard(
                icon: Icons.pending_actions_rounded,
                color: AppColors.warning,
                label: 'home.pending'.tr(),
                value: '3',
              ),
            ],
          ),
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
        _shimmerBox(double.infinity, 120.h, isDark),
        SizedBox(height: 24.h),
        _shimmerBox(100.w, 20.h, isDark),
        SizedBox(height: 16.h),
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
