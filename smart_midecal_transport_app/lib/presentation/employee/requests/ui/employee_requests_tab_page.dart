import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/bulk_request_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';
import 'cubit/blood_sample_cubit.dart';
import 'cubit/blood_sample_state.dart';
import 'widgets/loading_skeleton.dart';

/// Employee Requests Page – Bulk Blood Sample Request
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

// ──────────────────────────────────────────────────────────────
// Main view
// ──────────────────────────────────────────────────────────────
class _EmployeeRequestsView extends StatelessWidget {
  const _EmployeeRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BloodSampleCubit, BloodSampleState>(
      listener: (context, state) {
        // ── Error snackbar ────────────────────────────────────────
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

        // ── Bulk result bottom sheet ───────────────────────────────
        else if (state is BloodSampleBulkResult) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => _BulkResultsBottomSheet(
              successCount: state.successCount,
              failureCount: state.failureCount,
              failures: state.failures,
            ),
          );
        }

        // ── Token expired → logout ────────────────────────────────
        else if (state is BloodSampleTokenExpired) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Session expired. Please log in again.'),
              backgroundColor: AppColors.warning,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
          // Pop back to the login screen. Adjust route name to match your router.
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
        final String? selectedRoom =
            loaded?.selectedRoom ?? cubit.selectedRoom;
        final List<SampleEntity> results =
            loaded?.searchResults ?? cubit.searchResults;

        return SafeArea(
          child: Stack(
            children: [
              // ── Scrollable content ────────────────────────────────
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
                              _SearchSection(
                                cubit: cubit,
                                theme: theme,
                                state: state,
                              ),
                              SizedBox(height: 24.h),
                              // ── Room selector (visible when ≥1 sample selected) ──
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
                                    ? _RoomSelectorCard(
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

                        // ── Live search results overlay ───────────────
                        if (results.isNotEmpty)
                          _SearchResultsOverlay(
                            cubit: cubit,
                            theme: theme,
                            results: results,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // ── Floating selection/submit bar ─────────────────────
              _FloatingSelectionBar(
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
        padding: EdgeInsets.only(top: 80.h),
        child: Column(
          children: [
            Icon(
              Icons.biotech_outlined,
              size: 80.sp,
              color: theme.disabledColor.withValues(alpha: 0.4),
            ),
            SizedBox(height: 16.h),
            Text(
              'No samples selected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Search for a patient to add samples to your request',
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

// ──────────────────────────────────────────────────────────────
// Search Section
// ──────────────────────────────────────────────────────────────
class _SearchSection extends StatelessWidget {
  final BloodSampleCubit cubit;
  final ThemeData theme;
  final BloodSampleState state;

  const _SearchSection({
    required this.cubit,
    required this.theme,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Find Patient Sample',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: cubit.searchController,
          onChanged: cubit.searchSamples,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter Patient Name or ID...',
            prefixIcon: Icon(Icons.search, color: theme.primaryColor),
            suffixIcon: state is BloodSampleSearchLoading
                ? Padding(
                    padding: EdgeInsets.all(12.w),
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : (cubit.searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          cubit.searchSamples('');
                          cubit.searchController.clear();
                        },
                      )
                    : null),
            filled: true,
            fillColor: theme.cardColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.r),
              borderSide: BorderSide(color: theme.primaryColor, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.w,
              vertical: 16.h,
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Search results overlay (with multi-select checkboxes)
// ──────────────────────────────────────────────────────────────
class _SearchResultsOverlay extends StatelessWidget {
  final BloodSampleCubit cubit;
  final ThemeData theme;
  final List<SampleEntity> results;

  const _SearchResultsOverlay({
    required this.cubit,
    required this.theme,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 100.h,
      left: 24.w,
      right: 24.w,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.2),
            ),
          ),
          constraints: BoxConstraints(maxHeight: 280.h),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (_, __) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final sample = results[index];
              final isChecked = cubit.isSelected(sample.sampleCode!);

              return InkWell(
                onTap: () => cubit.toggleSampleSelection(sample),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 10.h,
                  ),
                  child: Row(
                    children: [
                      // Animated checkbox
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 24.w,
                        height: 24.w,
                        decoration: BoxDecoration(
                          color: isChecked
                              ? AppColors.buttonColor
                              : Colors.transparent,
                          border: Border.all(
                            color: isChecked
                                ? AppColors.buttonColor
                                : theme.dividerColor,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: isChecked
                            ? Icon(
                                Icons.check,
                                size: 16.sp,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      SizedBox(width: 14.w),
                      // Avatar
                      CircleAvatar(
                        radius: 20.r,
                        backgroundColor:
                            AppColors.buttonColor.withValues(alpha: 0.1),
                        child: Icon(
                          Icons.person,
                          color: AppColors.buttonColor,
                          size: 20.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      // Labels
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sample.patientName!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'Code: ${sample.sampleCode}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.labelColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status chip
                      _StatusChip(status: sample.status ?? ''),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Tiny status chip
// ──────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'IN_STORAGE' => Colors.blue,
      'REQUESTED' => Colors.orange,
      'OUT_FOR_DELIVERY' => Colors.green,
      _ => Colors.grey,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
          fontSize: 10.sp,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Room selector card
// ──────────────────────────────────────────────────────────────
class _RoomSelectorCard extends StatelessWidget {
  final String? selectedRoom;
  final void Function(String) onRoomSelected;
  final ThemeData theme;

  const _RoomSelectorCard({
    super.key,
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final rooms = ['Room A', 'Room B', 'Room C'];

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.meeting_room_outlined,
                  size: 20.sp,
                  color: AppColors.buttonColor,
                ),
                SizedBox(width: 8.w),
                Text(
                  'Select Delivery Room',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: rooms.map((room) {
                final isSelected = selectedRoom == room;
                return Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(right: room != rooms.last ? 10.w : 0),
                    child: InkWell(
                      onTap: () => onRoomSelected(room),
                      borderRadius: BorderRadius.circular(12.r),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.buttonColor
                              : theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.buttonColor
                                : theme.dividerColor.withValues(alpha: 0.15),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          room,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? Colors.white
                                : theme.textTheme.bodyLarge?.color,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Floating selection bar
// ──────────────────────────────────────────────────────────────
class _FloatingSelectionBar extends StatelessWidget {
  final List<String> selectedCodes;
  final bool isSubmitting;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const _FloatingSelectionBar({
    required this.selectedCodes,
    required this.isSubmitting,
    required this.onClear,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final isVisible = selectedCodes.isNotEmpty;

    return AnimatedPositioned(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      bottom: isVisible ? 20.h : -100.h,
      left: 24.w,
      right: 24.w,
      child: Material(
        borderRadius: BorderRadius.circular(20.r),
        elevation: 12,
        shadowColor: AppColors.buttonColor.withValues(alpha: 0.3),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryLight, Color(0xFF1565C0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              // Clear button
              GestureDetector(
                onTap: isSubmitting ? null : onClear,
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              // Selection count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${selectedCodes.length} sample${selectedCodes.length > 1 ? 's' : ''} selected',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      'Tap "Request" to submit',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Submit button
              SizedBox(
                height: 44.h,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : onSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.buttonColor,
                    disabledBackgroundColor:
                        Colors.white.withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 18.w),
                  ),
                  child: isSubmitting
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.buttonColor,
                          ),
                        )
                      : Text(
                          'Request',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.sp,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Bulk results bottom sheet
// ──────────────────────────────────────────────────────────────
class _BulkResultsBottomSheet extends StatelessWidget {
  final int successCount;
  final int failureCount;
  final List<BulkSampleFailedEntity> failures;

  const _BulkResultsBottomSheet({
    required this.successCount,
    required this.failureCount,
    required this.failures,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFailures = failures.isNotEmpty;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  margin: EdgeInsets.only(bottom: 20.h),
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),

              // Title
              Text(
                'Request Summary',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20.h),

              // Stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_rounded,
                      label: 'Successful',
                      count: successCount,
                      color: AppColors.success,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.cancel_rounded,
                      label: 'Failed',
                      count: failureCount,
                      color: failureCount > 0 ? AppColors.error : Colors.grey,
                    ),
                  ),
                ],
              ),

              // Failures list
              if (hasFailures) ...[
                SizedBox(height: 24.h),
                Text(
                  'Failed Samples',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                  ),
                ),
                SizedBox(height: 12.h),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 220.h),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: failures.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (context, index) {
                      final f = failures[index];
                      return Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.15),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 18.sp,
                            ),
                            SizedBox(width: 10.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    f.sampleCode ?? '—',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2.h),
                                  Text(
                                    f.errorMessage,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              SizedBox(height: 24.h),

              // Done button
              SizedBox(
                width: double.infinity,
                height: 52.h,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────
// Stat card widget used in the bottom sheet
// ──────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 10.h),
          Text(
            '$count',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
