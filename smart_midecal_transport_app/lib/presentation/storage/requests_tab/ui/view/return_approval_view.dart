import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../cubit/return_approval_cubit.dart';
import '../widgets/return_request_card.dart';
import '../widgets/loading_skeleton_card.dart';
import '../widgets/section_header.dart';

/// Return Approval View — Handles doctor return requests
class ReturnApprovalView extends StatefulWidget {
  const ReturnApprovalView({super.key});

  @override
  State<ReturnApprovalView> createState() => _ReturnApprovalViewState();
}

class _ReturnApprovalViewState extends State<ReturnApprovalView> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReturnApprovalCubit, ReturnApprovalState>(
      listener: (context, state) {
        if (state is ReturnApprovalActionSuccess) {
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
        } else if (state is ReturnApprovalActionError) {
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
          onRefresh: () => context.read<ReturnApprovalCubit>().refresh(),
          color: AppColors.primaryLight,
          child: _buildContent(context, state),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ReturnApprovalState state) {
    // ── Loading ─────────────────────────────────────────────────────────────
    if (state is ReturnApprovalLoading || state is ReturnApprovalInitial) {
      return ListView.builder(
        padding: EdgeInsets.all(16.w),
        itemCount: 4,
        itemBuilder: (_, __) => const LoadingSkeletonCard(),
      );
    }

    // ── Error ────────────────────────────────────────────────────────────────
    if (state is ReturnApprovalError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<ReturnApprovalCubit>().loadReturnRequests(),
      );
    }

    // ── Loaded / Action states ───────────────────────────────────────────────
    List<dynamic> returnRequests = [];
    if (state is ReturnApprovalLoaded) {
      returnRequests = state.returnRequests;
    } else if (state is ReturnApprovalActionSuccess) {
      returnRequests = state.returnRequests;
    }

    if (returnRequests.isEmpty) {
      return _EmptyView(
        onRefresh: () =>
            context.read<ReturnApprovalCubit>().loadReturnRequests(),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: returnRequests.length + 1, // +1 for the header
      itemBuilder: (context, index) {
        if (index == 0) {
          return SectionHeader(
            title: 'return_approval.pending_requests'.tr(),
            count: returnRequests.length,
            icon: Icons.assignment_return,
            color: AppColors.primaryLight,
          );
        }

        final request = returnRequests[index - 1];
        return ReturnRequestCard(
          returnRequest: request,
          onApprove: () => context.read<ReturnApprovalCubit>().approveReturn([
            request['id'],
          ]),
          onReject: () =>
              context.read<ReturnApprovalCubit>().rejectReturn([request['id']]),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.error),
          SizedBox(height: 16.h),
          Text(
            message,
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: Text('common.retry'.tr()),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onRefresh});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_return_outlined,
            size: 64.sp,
            color: AppColors.labelColor,
          ),
          SizedBox(height: 16.h),
          Text(
            'return_approval.no_pending_requests'.tr(),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'return_approval.all_requests_processed'.tr(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.labelColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text('common.refresh'.tr()),
          ),
        ],
      ),
    );
  }
}
