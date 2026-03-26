import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/restrictions_cubit.dart';
import 'cubit/restrictions_state.dart';
import 'widgets/restriction_toggle_tile.dart';

/// Restrictions Tab Page - Control access & operations
/// UI only dispatches events, all logic in cubit
class RestrictionsTabPage extends StatefulWidget {
  const RestrictionsTabPage({super.key});

  @override
  State<RestrictionsTabPage> createState() => _RestrictionsTabPageState();
}

class _RestrictionsTabPageState extends State<RestrictionsTabPage>
    with AutomaticKeepAliveClientMixin {
  late RestrictionsCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<RestrictionsCubit>()..loadData();
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
      child: BlocBuilder<RestrictionsCubit, RestrictionsState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<RestrictionsCubit>().refresh(),
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
    RestrictionsState state,
    ThemeData theme,
  ) {
    if (state is RestrictionsLoading || state is RestrictionsInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _buildLoadingSkeleton(theme),
      );
    }

    if (state is RestrictionsError) {
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
              onPressed: () => context.read<RestrictionsCubit>().loadData(),
              child: Text('employer.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is RestrictionsLoaded) {
      final cubit = context.read<RestrictionsCubit>();

      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Header
          Text(
            'employer.restrictions_title'.tr(),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'employer.restrictions_subtitle'.tr(),
            style: theme.textTheme.bodySmall,
          ),
          SizedBox(height: 24.h),

          // Restriction toggles
          RestrictionToggleTile(
            icon: Icons.science_rounded,
            iconColor: AppColors.info,
            title: 'employer.restrict_doctor_samples'.tr(),
            description: 'employer.restrict_doctor_samples_desc'.tr(),
            isRestricted: state.restrictDoctorSamples,
            onToggle: cubit.toggleDoctorSamples,
          ),

          RestrictionToggleTile(
            icon: Icons.bloodtype_rounded,
            iconColor: AppColors.error,
            title: 'employer.restrict_doctor_bags'.tr(),
            description: 'employer.restrict_doctor_bags_desc'.tr(),
            isRestricted: state.restrictDoctorBags,
            onToggle: cubit.toggleDoctorBags,
          ),

          RestrictionToggleTile(
            icon: Icons.add_box_rounded,
            iconColor: AppColors.success,
            title: 'employer.restrict_storage_bags'.tr(),
            description: 'employer.restrict_storage_bags_desc'.tr(),
            isRestricted: state.restrictStorageAddBags,
            onToggle: cubit.toggleStorageAddBags,
          ),

          RestrictionToggleTile(
            icon: Icons.biotech_rounded,
            iconColor: AppColors.secondary,
            title: 'employer.restrict_storage_samples'.tr(),
            description: 'employer.restrict_storage_samples_desc'.tr(),
            isRestricted: state.restrictStorageAddSamples,
            onToggle: cubit.toggleStorageAddSamples,
          ),

          RestrictionToggleTile(
            icon: Icons.local_shipping_rounded,
            iconColor: AppColors.warning,
            title: 'employer.restrict_transport_car'.tr(),
            description: 'employer.restrict_transport_car_desc'.tr(),
            isRestricted: state.restrictTransportCarItems,
            onToggle: cubit.toggleTransportCarItems,
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
        ...List.generate(
          5,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _shimmerBox(double.infinity, 100.h, isDark),
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
