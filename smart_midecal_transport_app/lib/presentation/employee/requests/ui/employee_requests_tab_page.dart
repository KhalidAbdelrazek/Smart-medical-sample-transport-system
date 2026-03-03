import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';
import 'cubit/blood_sample_cubit.dart';
import 'cubit/blood_sample_state.dart';
import 'widgets/request_form_fields.dart';
import 'widgets/loading_skeleton.dart';

/// Employee Requests Page focused on Blood Sample requests
/// Premium UI with real-time search and interactive details card
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

class _EmployeeRequestsView extends StatelessWidget {
  const _EmployeeRequestsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<BloodSampleCubit, BloodSampleState>(
      listener: (context, state) {
        if (state is BloodSampleError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        } else if (state is BloodSampleSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request submitted successfully!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is BloodSampleLoading) {
          return const RequestLoadingSkeleton();
        }

        final cubit = context.read<BloodSampleCubit>();
        final theme = Theme.of(context);

        return SafeArea(
          child: Column(
            children: [
              _buildHeader(theme),
              Expanded(
                child: Stack(
                  children: [
                    SingleChildScrollView(
                      padding: EdgeInsets.symmetric(
                        horizontal: 24.w,
                        vertical: 20.h,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSearchSection(context, cubit, theme, state),
                          SizedBox(height: 24.h),
                          if (state is BloodSampleLoaded &&
                              state.selectedSample != null)
                            _SampleDetailsCard(
                              sample: state.selectedSample!,
                              selectedRoom: state.selectedRoom,
                              onRoomSelected: (room) => cubit.selectRoom(room),
                              onConfirm: () => cubit.submitRequest(),
                              isSubmitting: state is BloodSampleSubmitting,
                            )
                          else
                            _buildEmptyState(theme),
                        ],
                      ),
                    ),
                    if (state is BloodSampleLoaded &&
                        state.searchResults.isNotEmpty)
                      _buildSearchResultsOverlay(
                        context,
                        cubit,
                        theme,
                        state.searchResults,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      //   padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      //   width: double.infinity,
      //   color: theme.scaffoldBackgroundColor,
      //   child: Column(
      //     crossAxisAlignment: CrossAxisAlignment.start,
      //     children: [
      //       Text(
      //         'Search and manage patient blood samples',
      //         style: theme.textTheme.bodyMedium?.copyWith(
      //           color: AppColors.labelColor,
      //         ),
      //       ),
      //     ],
      //   ),
    );
  }

  Widget _buildSearchSection(
    BuildContext context,
    BloodSampleCubit cubit,
    ThemeData theme,
    BloodSampleState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RequestFormFields.label('Find Patient Sample', theme),
        SizedBox(height: 12.h),
        TextField(
          controller: cubit.searchController,
          onChanged: (query) => cubit.searchSamples(query),
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

  Widget _buildSearchResultsOverlay(
    BuildContext context,
    BloodSampleCubit cubit,
    ThemeData theme,
    List<SampleEntity> results,
  ) {
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
          constraints: BoxConstraints(maxHeight: 250.h),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: results.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
            itemBuilder: (context, index) {
              final sample = results[index];
              return ListTile(
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 4.h,
                ),
                leading: CircleAvatar(
                  backgroundColor: AppColors.buttonColor.withValues(alpha: 0.1),
                  child: Icon(
                    Icons.person,
                    color: AppColors.buttonColor,
                    size: 20.sp,
                  ),
                ),
                title: Text(
                  sample.patientName!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'ID: ${sample.sampleCode}',
                  style: theme.textTheme.bodySmall,
                ),
                onTap: () => cubit.selectSample(sample),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: 100.h),
        child: Column(
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80.sp,
              color: theme.disabledColor.withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'No sample selected',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.disabledColor,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Search for a patient to view details and request delivery',
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

class _SampleDetailsCard extends StatelessWidget {
  final SampleEntity sample;
  final String? selectedRoom;
  final Function(String) onRoomSelected;
  final VoidCallback onConfirm;
  final bool isSubmitting;

  const _SampleDetailsCard({
    required this.sample,
    required this.selectedRoom,
    required this.onRoomSelected,
    required this.onConfirm,
    required this.isSubmitting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(theme),
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow(
                  Icons.fingerprint,
                  'Sample ID',
                  sample.sampleCode!,
                  theme,
                ),
                SizedBox(height: 16.h),
                _buildInfoRow(
                  Icons.person_outline,
                  'Patient Name',
                  sample.patientName!,
                  theme,
                ),
                SizedBox(height: 16.h),
                _buildStatusRow(theme),
                SizedBox(height: 32.h),
                Text(
                  'Select Delivery Room',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.h),
                _RoomSelector(
                  selectedRoom: selectedRoom,
                  onRoomSelected: onRoomSelected,
                ),
                SizedBox(height: 40.h),
                _buildConfirmButton(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: AppColors.buttonColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.biotech_rounded,
            color: AppColors.buttonColor,
            size: 24.sp,
          ),
          SizedBox(width: 12.w),
          Text(
            'Sample Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.buttonColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: theme.disabledColor),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.labelColor,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusRow(ThemeData theme) {
    Color statusColor;
    switch (sample.status) {
      case 'IN_STORAGE':
        statusColor = Colors.blue;
        break;
      case 'REQUESTED':
        statusColor = Colors.orange;
        break;
      case 'OUT_FOR_DELIVERY':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Row(
      children: [
        Icon(Icons.info_outline, size: 20.sp, color: theme.disabledColor),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.labelColor,
              ),
            ),
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                sample.status!.replaceAll('_', ' '),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConfirmButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      height: 54.h,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onConfirm,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.buttonColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                'Confirm Request',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

class _RoomSelector extends StatelessWidget {
  final String? selectedRoom;
  final Function(String) onRoomSelected;

  const _RoomSelector({
    required this.selectedRoom,
    required this.onRoomSelected,
  });

  @override
  Widget build(BuildContext context) {
    final rooms = ['Room A', 'Room B', 'Room C'];
    final theme = Theme.of(context);

    return Row(
      children: rooms.map((room) {
        final isSelected = selectedRoom == room;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: room != rooms.last ? 12.w : 0),
            child: InkWell(
              onTap: () => onRoomSelected(room),
              borderRadius: BorderRadius.circular(12.r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.buttonColor : theme.cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.buttonColor
                        : theme.dividerColor.withValues(alpha: 0.1),
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
    );
  }
}
