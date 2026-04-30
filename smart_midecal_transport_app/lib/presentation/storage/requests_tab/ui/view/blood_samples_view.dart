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
    final pendingRequests = requests
        .where(
          (r) =>
              r.status?.toUpperCase() == 'PENDING' ||
              r.status?.toUpperCase() == 'REQUESTED',
        )
        .toList();
    final otherRequests = requests
        .where(
          (r) =>
              r.status?.toUpperCase() != 'PENDING' &&
              r.status?.toUpperCase() != 'REQUESTED',
        )
        .toList();

    return ListView(
      key: const ValueKey('loaded'),
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
      children: [
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
              index: entry.key,
              onAddToCar: isLoading
                  ? null
                  : () => cubit.addToCar(
                      req.id ?? '',
                      req.sample?.sampleCode ?? '',
                    ),
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
              index: pendingRequests.length + entry.key,
              // No action button for non-pending requests
              onAddToCar: null,
            );
          }),
        ],
      ],
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
