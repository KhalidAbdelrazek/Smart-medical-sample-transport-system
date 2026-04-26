import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import 'cubit/restrictions_cubit.dart';
import 'cubit/restrictions_state.dart';
import 'widgets/global_toggle_row.dart';
import 'widgets/partial_restriction_panel.dart';
import 'widgets/restriction_section_card.dart';

/// Restrictions Tab — Admin control panel for operation restrictions.
/// All logic lives in [RestrictionsCubit]. UI purely emits events.
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

    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<RestrictionsCubit, RestrictionsState>(
        listenWhen: (prev, curr) {
          if (prev is! RestrictionsLoaded || curr is! RestrictionsLoaded) {
            return false;
          }
          // Show snackbar when a loading flag clears → action completed
          return (prev.isDoctorLoading && !curr.isDoctorLoading) ||
              (prev.isStorageLoading && !curr.isStorageLoading) ||
              (prev.isCarLoading && !curr.isCarLoading);
        },
        listener: (context, state) {
          if (state is RestrictionsLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Restriction updated successfully'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<RestrictionsCubit>().refresh(),
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

  Widget _buildContent(BuildContext context, RestrictionsState state) {
    if (state is RestrictionsLoading || state is RestrictionsInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: _RestrictionsSkeletonScreen(),
      );
    }

    if (state is RestrictionsError) {
      return _ErrorBody(
        key: const ValueKey('error'),
        message: state.message,
        isNetwork: state.isNetwork,
        onRetry: () => context.read<RestrictionsCubit>().loadData(),
      );
    }

    if (state is RestrictionsLoaded) {
      return _LoadedBody(key: const ValueKey('loaded'), state: state);
    }

    return const SizedBox.shrink(key: ValueKey('empty'));
  }
}

// ─── Loaded body ────────────────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  final RestrictionsLoaded state;

  const _LoadedBody({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RestrictionsCubit>();
    final theme = Theme.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
      children: [
        // ── Header ───────────────────────────────────────────────────
        _Header(theme: theme),
        SizedBox(height: 24.h),

        // ════════════════════════════════════════════════════════════
        // 1. Doctor Sample Restrictions
        // ════════════════════════════════════════════════════════════
        RestrictionSectionCard(
          icon: Icons.medical_services_rounded,
          accentColor: AppColors.info,
          title: 'Doctor Sample Requests',
          subtitle: 'Control which doctors can submit sample requests',
          child: Column(
            children: [
              // Global toggle
              GlobalToggleRow(
                label: 'Restrict All Doctors',
                description: 'Block all doctors from submitting requests',
                isOn: state.isDoctorGloballyRestricted,
                isLoading: state.isDoctorLoading,
                activeColor: AppColors.error,
                onChanged: (v) => cubit.toggleDoctorGlobal(v),
              ),
              SizedBox(height: 12.h),

              // Partial restriction panel
              PartialRestrictionPanel(
                title: 'Restrict Specific Doctors',
                accentColor: AppColors.info,
                isExpanded: state.isDoctorPartialExpanded,
                isLoading: state.isDoctorLoading,
                isListLoading: state.isDoctorListLoading,
                people: state.filteredDoctors,
                selectedIds: state.selectedDoctorIds,
                searchQuery: state.doctorSearchQuery,
                onToggleExpand: cubit.toggleDoctorPartialExpanded,
                onTogglePerson: cubit.toggleDoctorSelection,
                onSelectAll: cubit.selectAllDoctors,
                onClearAll: cubit.clearAllDoctors,
                onApply: cubit.applyPartialDoctorRestriction,
                onSearchChanged: cubit.updateDoctorSearch,
              ),
            ],
          ),
        ),

        // ════════════════════════════════════════════════════════════
        // 2. Storage Sample Restrictions
        // ════════════════════════════════════════════════════════════
        RestrictionSectionCard(
          icon: Icons.warehouse_rounded,
          accentColor: AppColors.success,
          title: 'Storage Sample Loading',
          subtitle: 'Control which storage employees can load samples',
          child: Column(
            children: [
              // Global toggle
              GlobalToggleRow(
                label: 'Restrict All Storage Employees',
                description:
                    'Block all storage employees from loading samples',
                isOn: state.isStorageGloballyRestricted,
                isLoading: state.isStorageLoading,
                activeColor: AppColors.error,
                onChanged: (v) => cubit.toggleStorageGlobal(v),
              ),
              SizedBox(height: 12.h),

              // Partial restriction panel
              PartialRestrictionPanel(
                title: 'Restrict Specific Storage Employees',
                accentColor: AppColors.success,
                isExpanded: state.isStoragePartialExpanded,
                isLoading: state.isStorageLoading,
                isListLoading: state.isStorageListLoading,
                people: state.filteredStorageEmployees,
                selectedIds: state.selectedStorageIds,
                searchQuery: state.storageSearchQuery,
                onToggleExpand: cubit.toggleStoragePartialExpanded,
                onTogglePerson: cubit.toggleStorageSelection,
                onSelectAll: cubit.selectAllStorageEmployees,
                onClearAll: cubit.clearAllStorageEmployees,
                onApply: cubit.applyPartialStorageRestriction,
                onSearchChanged: cubit.updateStorageSearch,
              ),
            ],
          ),
        ),

        // ════════════════════════════════════════════════════════════
        // 3. Transport Car Restriction
        // ════════════════════════════════════════════════════════════
        RestrictionSectionCard(
          icon: Icons.local_shipping_rounded,
          accentColor: AppColors.warning,
          title: 'Transport Car Dispatch',
          subtitle: 'Enable or disable car dispatch operations',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlobalToggleRow(
                label: 'Restrict Transport Car',
                description: 'Prevent the transport car from being dispatched',
                isOn: state.carRestricted,
                isLoading: state.isCarLoading,
                activeColor: AppColors.warning,
                onChanged: (v) => cubit.toggleCarRestriction(v),
              ),
              if (state.carRestricted) ...[
                SizedBox(height: 12.h),
                _CarInfoChip(),
              ],
            ],
          ),
        ),

        SizedBox(height: 16.h),

        // ── Legend ─────────────────────────────────────────────────
        _StatusLegend(),
      ],
    );
  }
}

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final ThemeData theme;
  const _Header({required this.theme});

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
                'Access Restrictions',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 20.sp,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                'Control system-wide operational permissions',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.labelColor,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12.w),
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
                Icons.admin_panel_settings_rounded,
                size: 14.sp,
                color: Colors.white,
              ),
              SizedBox(width: 5.w),
              Text(
                'ADMIN',
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

// ─── Car info chip ───────────────────────────────────────────────────────────

class _CarInfoChip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16.sp,
            color: AppColors.warning,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Transport car (Car #1) is currently restricted. '
              'No dispatch operations will be allowed.',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 11.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Status legend ───────────────────────────────────────────────────────────

class _StatusLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Status Reference',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12.sp,
              color: AppColors.labelColor,
            ),
          ),
          SizedBox(height: 10.h),
          _LegendItem(
            color: AppColors.success,
            label: 'Active',
            description: 'Operations are allowed (no restriction)',
          ),
          _LegendItem(
            color: AppColors.error,
            label: 'Restricted',
            description: 'All operations are blocked globally',
          ),
          _LegendItem(
            color: AppColors.info,
            label: 'Partial',
            description: 'Only selected individuals are restricted',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String description;

  const _LegendItem({
    required this.color,
    required this.label,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h),
      child: Row(
        children: [
          Container(
            width: 10.w,
            height: 10.w,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '$label — ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11.sp,
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                color: AppColors.labelColor,
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Error body ──────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String message;
  final bool isNetwork;
  final VoidCallback onRetry;

  const _ErrorBody({
    super.key,
    required this.message,
    required this.isNetwork,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                size: 48.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              isNetwork ? 'No Internet Connection' : 'Something went wrong',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.labelColor,
              ),
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 12.h,
                ),
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Skeleton loader ─────────────────────────────────────────────────────────

class _RestrictionsSkeletonScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 40.h),
      children: [
        _Shimmer(width: 180.w, height: 24.h, isDark: isDark),
        SizedBox(height: 6.h),
        _Shimmer(width: 260.w, height: 14.h, isDark: isDark),
        SizedBox(height: 28.h),
        ...List.generate(
          3,
          (_) => Padding(
            padding: EdgeInsets.only(bottom: 16.h),
            child: _Shimmer(
              width: double.infinity,
              height: 160.h,
              isDark: isDark,
            ),
          ),
        ),
      ],
    );
  }
}

class _Shimmer extends StatefulWidget {
  final double width;
  final double height;
  final bool isDark;

  const _Shimmer({
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: (widget.isDark ? Colors.white : Colors.grey)
              .withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(16.r),
        ),
      ),
    );
  }
}
