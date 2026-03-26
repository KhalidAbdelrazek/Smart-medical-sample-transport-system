import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/transport_request_entity.dart';

import 'cubit/my_requests_cubit.dart';
import 'cubit/my_requests_state.dart';
import 'widgets/empty_requests_widget.dart';
import 'widgets/error_retry_widget.dart';
import 'widgets/my_requests_loading_skeleton.dart';
import 'widgets/transport_request_card.dart';

/// View that renders My Requests state using [MyRequestsCubit].
/// Pure UI — no business logic.
class MyRequestsView extends StatelessWidget {
  const MyRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MyRequestsCubit, MyRequestsState>(
      listenWhen: (_, curr) =>
          curr is MyRequestsTokenExpired ||
          curr is MyRequestsCancelSuccess ||
          curr is MyRequestsCancelError,
      listener: (context, state) {
        if (state is MyRequestsTokenExpired) {
          _showSessionExpiredAndLogout(context);
        } else if (state is MyRequestsCancelSuccess) {
          _showSnackBar(
            context,
            'my_requests.cancelled_success'.tr(),
            AppColors.success,
          );
        } else if (state is MyRequestsCancelError) {
          _showSnackBar(context, state.message, AppColors.error);
        }
      },
      buildWhen: (_, curr) =>
          curr is MyRequestsInitial ||
          curr is MyRequestsLoading ||
          curr is MyRequestsLoaded ||
          curr is MyRequestsEmpty ||
          curr is MyRequestsCancelling ||
          curr is MyRequestsCancelError ||
          curr is MyRequestsError,
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<MyRequestsCubit>().refresh(),
          color: AppColors.primaryLight,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 280),
            child: _buildContent(context, state),
          ),
        );
      },
    );
  }

  // ── Content builder ────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, MyRequestsState state) {
    // Loading
    if (state is MyRequestsLoading || state is MyRequestsInitial) {
      return const MyRequestsLoadingSkeleton(key: ValueKey('loading'));
    }

    // Generic load error
    if (state is MyRequestsError) {
      return ErrorRetryWidget(
        key: const ValueKey('error'),
        message: state.message,
        onRetry: () => context.read<MyRequestsCubit>().loadMyRequests(),
      );
    }

    // Empty
    if (state is MyRequestsEmpty) {
      // Wrap in scrollable so pull-to-refresh still works when empty.
      return CustomScrollView(
        key: const ValueKey('empty'),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: const EmptyRequestsWidget(),
          ),
        ],
      );
    }

    // Extract list + cancelling ID from the relevant states
    List<TransportRequestEntity> requests = [];
    String? cancellingId;

    if (state is MyRequestsLoaded) {
      requests = state.requests;
    } else if (state is MyRequestsCancelling) {
      requests = state.requests;
      cancellingId = state.cancellingId;
    } else if (state is MyRequestsCancelError) {
      requests = state.requests;
    }

    if (requests.isEmpty) {
      return const EmptyRequestsWidget(key: ValueKey('empty'));
    }

    final cubit = context.read<MyRequestsCubit>();

    return ListView.separated(
      key: const ValueKey('loaded'),
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
      itemCount: requests.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (_, i) {
        final req = requests[i];
        final isCancelling = cancellingId == req.requestId;
        final isPending =
            (req.requestStatus ?? '').toUpperCase() == 'PENDING';

        return TransportRequestCard(
          key: ValueKey(req.requestId),
          request: req,
          isCancelling: isCancelling,
          onCancel: isPending && !isCancelling
              ? () => _showCancelDialog(context, cubit, req.requestId!)
              : null,
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void _showCancelDialog(
    BuildContext context,
    MyRequestsCubit cubit,
    String requestId,
  ) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        title: Text(
          'my_requests.cancel_confirm_title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        content: Text('my_requests.cancel_confirm_body'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'my_requests.cancel_confirm_no'.tr(),
              style: const TextStyle(color: AppColors.labelColor),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.r),
              ),
            ),
            child: Text('my_requests.cancel_confirm_yes'.tr()),
          ),
        ],
      ),
    ).then((confirmed) {
      if (confirmed == true) {
        cubit.cancelRequest(requestId);
      }
    });
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }

  void _showSessionExpiredAndLogout(BuildContext context) {
    _showSnackBar(
      context,
      'my_requests.session_expired'.tr(),
      AppColors.warning,
    );
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }
}
