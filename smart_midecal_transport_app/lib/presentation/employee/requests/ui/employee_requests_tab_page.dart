import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';

// Cubit & State
import 'cubit/blood_sample_cubit.dart';
import 'cubit/blood_sample_state.dart';

// UI Widgets
import 'widgets/loading_skeleton.dart';
import 'widgets/search_section.dart';
import 'widgets/room_selector_card.dart';
import 'widgets/floating_selection_bar.dart';
import 'widgets/search_results_overlay.dart';
import 'widgets/bulk_results_bottom_sheet.dart';

/// Employee Requests Page â€“ Bulk Blood Sample Request
/// Supports multi-selection, a floating selection bar, and a results bottom sheet.
class EmployeeRequestsTabPage extends StatelessWidget {
  const EmployeeRequestsTabPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<BloodSampleCubit>()..loadData(),
      child: const _EmployeeRequestsView(),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
// Main view
// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _EmployeeRequestsView extends StatelessWidget {
  const _EmployeeRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BloodSampleCubit, BloodSampleState>(
      listener: (context, state) {
        // â”€â”€ Error snackbar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (state is BloodSampleError) {
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

        // â”€â”€ Bulk result bottom sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        else if (state is BloodSampleBulkResult) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => BulkResultsBottomSheet(
              successCount: state.successCount,
              failureCount: state.failureCount,
              failures: state.failures,
            ),
          );
        }

        // â”€â”€ Token expired â†’ logout â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        else if (state is BloodSampleTokenExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('my_requests.session_expired'.tr()),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
          // Pop back to the login screen
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/login',
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state is BloodSampleLoading) {
          return const RequestLoadingSkeleton();
        }

        final cubit = context.read<BloodSampleCubit>();
        final theme = Theme.of(context);
        final loaded = state is BloodSampleLoaded ? state : null;
        final isSubmitting = state is BloodSampleSubmitting;

        final List<String> selectedCodes =
            loaded?.selectedSampleCodes ?? cubit.selectedSampleCodes;
        final String? selectedRoom = loaded?.selectedRoom ?? cubit.selectedRoom;
        final List<SampleEntity> results =
            loaded?.searchResults ?? cubit.searchResults;

        return SafeArea(
          child: Stack(
            children: [
              // â”€â”€ Scrollable content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              Column(
                children: [
                  Expanded(
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            24.w,
                            20.h,
                            24.w,
                            // Extra bottom padding so content doesn't hide behind
                            // the floating bar when selections are active.
                            selectedCodes.isNotEmpty ? 110.h : 20.h,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SearchSection(
                                cubit: cubit,
                                state: state,
                              ),
                              SizedBox(height: 24.h),
                              // â”€â”€ Room selector (visible when >=1 sample selected) â”€â”€
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                transitionBuilder: (child, animation) =>
                                    FadeTransition(
                                  opacity: animation,
                                  child: SizeTransition(
                                    sizeFactor: animation,
                                    child: child,
                                  ),
                                ),
                                child: selectedCodes.isNotEmpty
                                    ? RoomSelectorCard(
                                        key: const ValueKey('room'),
                                        selectedRoom: selectedRoom,
                                        onRoomSelected: cubit.selectRoom,
                                        theme: theme,
                                      )
                                    : _buildEmptyState(theme),
                              ),
                            ],
                          ),
                        ),

                        // â”€â”€ Live search results overlay â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        if (results.isNotEmpty)
                          SearchResultsOverlay(
                            cubit: cubit,
                            theme: theme,
                            results: results,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // â”€â”€ Floating selection/submit bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
              FloatingSelectionBar(
                selectedCodes: selectedCodes,
                isSubmitting: isSubmitting,
                onClear: cubit.clearSelections,
                onSubmit: cubit.submitRequest,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsetsDirectional.only(top: 80.h),
        child: Column(
          children: [
            Icon(
              Icons.biotech_outlined,
              size: 80.sp,
              color: theme.disabledColor.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text('extra.no_samples_selected'.tr(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text('extra.search_patient'.tr(),
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

