import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../cubit/blood_samples_cubit.dart';
import '../cubit/blood_samples_state.dart';
import '../widgets/loading_skeleton_card.dart';
import '../widgets/car_status_widget.dart';
import '../widgets/blood_sample_card.dart';
import '../widgets/section_header.dart';

/// Blood Samples sub-tab view
class BloodSamplesView extends StatelessWidget {
  const BloodSamplesView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocBuilder<BloodSamplesCubit, BloodSamplesState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () => context.read<BloodSamplesCubit>().refresh(),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildContent(context, state, theme),
          ),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    BloodSamplesState state,
    ThemeData theme,
  ) {
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

    if (state is BloodSamplesError) {
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
              onPressed: () => context.read<BloodSamplesCubit>().loadRequests(),
              child: Text('requests.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is BloodSamplesLoaded) {
      final cubit = context.read<BloodSamplesCubit>();

      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.all(16.w),
        children: [
          // Car Status
          CarStatusWidget(
            car: state.car,
            onDispatch: state.car.isEmpty ? null : cubit.dispatchCar,
          ),
          SizedBox(height: 16.h),

          // Added to Car Section
          if (state.addedToCarRequests.isNotEmpty) ...[
            SectionHeader(
              title: 'requests.added_to_car'.tr(),
              count: state.addedCount,
              icon: Icons.check_circle_rounded,
              color: AppColors.success,
            ),
            ...state.addedToCarRequests.asMap().entries.map((entry) {
              return BloodSampleCard(
                request: entry.value,
                isInCar: true,
                index: entry.key,
                onAction: () => cubit.removeFromCar(entry.value.id),
              );
            }),
            SizedBox(height: 8.h),
          ],

          // Pending Section
          SectionHeader(
            title: 'requests.pending_requests'.tr(),
            count: state.pendingCount,
            icon: Icons.pending_actions_rounded,
            color: AppColors.warning,
          ),
          if (state.pendingRequests.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 32.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_rounded,
                      size: 48.sp,
                      color: theme.disabledColor,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'requests.no_pending'.tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.disabledColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...state.pendingRequests.asMap().entries.map((entry) {
              return BloodSampleCard(
                request: entry.value,
                isInCar: false,
                index: entry.key,
                onAction: state.car.isFull
                    ? null
                    : () => cubit.addToCar(entry.value.id),
              );
            }),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
