import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/storage/requests_tab/domain/models/get_requests_response_entity.dart';

import '../cubit/blood_samples_cubit.dart';
import '../cubit/blood_samples_state.dart';
import '../widgets/blood_sample_card.dart';
import '../widgets/loading_skeleton_card.dart';
import '../widgets/section_header.dart';

/// Blood Samples view — consumes [BloodSamplesCubit] state and renders UI only.
/// No business logic here.
class BloodSamplesView extends StatelessWidget {
  const BloodSamplesView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BloodSamplesCubit, BloodSamplesState>(
      // Only rebuild the list when these transition types arrive
      buildWhen: (prev, curr) =>
          curr is BloodSamplesLoading ||
          curr is BloodSamplesInitial ||
          curr is BloodSamplesLoaded ||
          curr is BloodSamplesError ||
          curr is BloodSamplesActionSuccess ||
          curr is BloodSamplesActionError,
      listenWhen: (prev, curr) =>
          curr is BloodSamplesActionSuccess || curr is BloodSamplesActionError,
      listener: (context, state) {
        if (state is BloodSamplesActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        } else if (state is BloodSamplesActionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<BloodSamplesCubit>().refresh(),
          color: AppColors.primaryLight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildContent(context, state),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, BloodSamplesState state) {
    // ── Loading ─────────────────────────────────────────────────────────────
    if (state is BloodSamplesLoading || state is BloodSamplesInitial) {
      return IgnorePointer(
        key: const ValueKey('loading'),
        child: ListView.builder(
          padding: EdgeInsets.all(16.w),
          itemCount: 4,
          itemBuilder: (_, __) => const LoadingSkeletonCard(),
        ),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (state is BloodSamplesError) {
      return _ErrorView(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => context.read<BloodSamplesCubit>().loadRequests(),
      );
    }

    // ── Loaded / Action states ───────────────────────────────────────────────
    List<TransportRequestEntity> requests = [];
    String? actionLoadingId;

    if (state is BloodSamplesLoaded) {
      requests = state.requests;
      actionLoadingId = state.actionLoadingId;
    } else if (state is BloodSamplesActionSuccess) {
      requests = state.requests;
    } else if (state is BloodSamplesActionError) {
      requests = state.requests;
    }

    if (requests.isEmpty) {
      return _EmptyView(key: const ValueKey('empty'));
    }

    final cubit = context.read<BloodSamplesCubit>();

    // Partition requests into sections
    final pendingRequests = requests
        .where(
          (r) =>
              r.status?.toUpperCase() == 'PENDING' ||
              r.status?.toUpperCase() == 'REQUESTED',
        )
        .toList();

    final loadedRequests = requests
        .where(
          (r) =>
              r.status?.toUpperCase() == 'LOADED' ||
              r.status?.toUpperCase() == 'LOADED_FOR_RETURN',
        )
        .toList();

    final otherRequests = requests
        .where(
          (r) =>
              r.status?.toUpperCase() != 'PENDING' &&
              r.status?.toUpperCase() != 'REQUESTED' &&
              r.status?.toUpperCase() != 'LOADED' &&
              r.status?.toUpperCase() != 'LOADED_FOR_RETURN',
        )
        .toList();

    final isDispatchLoading = actionLoadingId == 'dispatch';

    return ListView(
      key: const ValueKey('loaded'),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
        // ── Dispatch Car Button (shown when ≥1 sample is loaded) ────────────
        if (loadedRequests.isNotEmpty) ...[
          _DispatchCarButton(
            isLoading: isDispatchLoading,
            loadedCount: loadedRequests.length,
            onDispatch: isDispatchLoading ? null : () => cubit.dispatchCar(),
          ),
          SizedBox(height: 16.h),
        ],

        // ── Loaded Section ──────────────────────────────────────────────────
        if (loadedRequests.isNotEmpty) ...[
          SectionHeader(
            title: 'requests.loaded_in_car'.tr(),
            count: loadedRequests.length,
            icon: Icons.inventory_2_rounded,
            color: AppColors.primaryLight,
          ),
          ...loadedRequests.asMap().entries.map((entry) {
            final req = entry.value;
            final isLoading = actionLoadingId == req.id;
            return BloodSampleCard(
              request: req,
              isActionLoading: isLoading,
              index: entry.key,
              onAddToCar: null,
              onRemoveFromCar: isLoading
                  ? null
                  : () => cubit.removeFromCar(req.id ?? ''),
            );
          }),
          SizedBox(height: 8.h),
        ],

        // ── Pending Section ─────────────────────────────────────────────────
        if (pendingRequests.isNotEmpty) ...[
          SectionHeader(
            title: 'requests.pending_requests'.tr(),
            count: pendingRequests.length,
            icon: Icons.pending_actions_rounded,
            color: AppColors.warning,
          ),
          ...pendingRequests.asMap().entries.map((entry) {
            final req = entry.value;
            final isLoading = actionLoadingId == req.id;
            return BloodSampleCard(
              request: req,
              isActionLoading: isLoading,
              index: loadedRequests.length + entry.key,
              onAddToCar: isLoading
                  ? null
                  : () => cubit.addToCar(
                      req.id ?? '',
                      req.sample?.sampleCode ?? '',
                    ),
              onRemoveFromCar: null,
            );
          }),
          SizedBox(height: 8.h),
        ],

        // ── Other Requests Section ──────────────────────────────────────────
        if (otherRequests.isNotEmpty) ...[
          SectionHeader(
            title: 'requests.other_requests'.tr(),
            count: otherRequests.length,
            icon: Icons.assignment_rounded,
            color: AppColors.info,
          ),
          ...otherRequests.asMap().entries.map((entry) {
            final req = entry.value;
            return BloodSampleCard(
              request: req,
              isActionLoading: false,
              index: loadedRequests.length + pendingRequests.length + entry.key,
              onAddToCar: null,
              onRemoveFromCar: null,
            );
          }),
        ],
      ],
    );
  }
}

// ── Dispatch Car Button ──────────────────────────────────────────────────────

class _DispatchCarButton extends StatelessWidget {
  final bool isLoading;
  final int loadedCount;
  final VoidCallback? onDispatch;

  const _DispatchCarButton({
    required this.isLoading,
    required this.loadedCount,
    this.onDispatch,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      decoration: BoxDecoration(
        gradient: isLoading
            ? null
            : LinearGradient(
                colors: [
                  AppColors.primaryLight,
                  AppColors.primaryLight.withValues(alpha: 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: isLoading ? AppColors.primaryLight.withValues(alpha: 0.5) : null,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isLoading
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryLight.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onDispatch,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            child: Row(
              children: [
                // Icon or spinner
                Container(
                  width: 44.w,
                  height: 44.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: isLoading
                      ? Padding(
                          padding: EdgeInsets.all(10.w),
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.local_shipping_rounded,
                          color: Colors.white,
                          size: 24.sp,
                        ),
                ),
                SizedBox(width: 16.w),

                // Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLoading
                            ? 'requests.dispatching'.tr()
                            : 'requests.dispatch_car'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '$loadedCount ${'requests.samples_ready'.tr()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow
                if (!isLoading)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.white.withValues(alpha: 0.8),
                    size: 16.sp,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
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
                Icons.wifi_off_rounded,
                size: 48.sp,
                color: AppColors.error,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'requests.error_title'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.labelColor,
              ),
            ),
            SizedBox(height: 24.h),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text('requests.retry'.tr()),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 13.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({super.key});

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
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.science_outlined,
                size: 56.sp,
                color: AppColors.info.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'requests.no_requests'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'requests.no_requests_subtitle'.tr(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.labelColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
