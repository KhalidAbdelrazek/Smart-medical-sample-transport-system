import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../cubit/blood_sample_cubit.dart';
import '../cubit/blood_sample_state.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_form_fields.dart';
import '../widgets/request_list_card.dart';
import '../widgets/loading_skeleton.dart';

/// Blood Sample Request View
/// Includes a request form and recent sample requests list
class BloodSampleView extends StatefulWidget {
  const BloodSampleView({super.key});

  @override
  State<BloodSampleView> createState() => _BloodSampleViewState();
}

class _BloodSampleViewState extends State<BloodSampleView>
    with AutomaticKeepAliveClientMixin {
  late BloodSampleCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = BloodSampleCubit()..loadData();
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
      child: BlocBuilder<BloodSampleCubit, BloodSampleState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => _cubit.refresh(),
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
    BloodSampleState state,
    ThemeData theme,
  ) {
    if (state is BloodSampleLoading || state is BloodSampleInitial) {
      return const RequestLoadingSkeleton(key: ValueKey('loading'));
    }

    if (state is BloodSampleError) {
      return Center(
        key: const ValueKey('error'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
            SizedBox(height: 16.h),
            Text(state.message),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () => _cubit.loadData(),
              child: Text('employee.retry'.tr()),
            ),
          ],
        ),
      );
    }

    if (state is BloodSampleLoaded) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // Request form
          RequestFormCard(
            children: [
              // Patient name
              RequestFormFields.label(
                'employee.sample_patient_name'.tr(),
                theme,
              ),
              SizedBox(height: 8.h),
              RequestFormFields.inputField(
                controller: _cubit.patientController,
                hint: 'employee.sample_enter_patient'.tr(),
                theme: theme,
              ),
              SizedBox(height: 16.h),

              // Blood type
              RequestFormFields.label('employee.sample_blood_type'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.dropdown(
                selectedValue: _cubit.selectedBloodType,
                items: _cubit.bloodTypes,
                hint: 'employee.sample_select_blood'.tr(),
                theme: theme,
                onChanged: (v) => setState(() => _cubit.selectedBloodType = v),
              ),
              SizedBox(height: 16.h),

              // Urgency
              RequestFormFields.label('employee.sample_urgency'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.urgencySelector(
                selected: _cubit.urgency,
                options: [
                  {'value': 'normal', 'label': 'employee.sample_normal'.tr()},
                  {'value': 'urgent', 'label': 'employee.sample_urgent'.tr()},
                  {
                    'value': 'critical',
                    'label': 'employee.sample_critical'.tr(),
                  },
                ],
                theme: theme,
                onChanged: (v) => setState(() => _cubit.urgency = v),
              ),
              SizedBox(height: 16.h),

              // Location
              RequestFormFields.label('employee.sample_location'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.inputField(
                controller: _cubit.locationController,
                hint: 'employee.sample_enter_location'.tr(),
                theme: theme,
              ),
              SizedBox(height: 16.h),

              // Notes
              RequestFormFields.label('employee.sample_notes'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.inputField(
                controller: _cubit.notesController,
                hint: 'employee.sample_notes_hint'.tr(),
                theme: theme,
                maxLines: 3,
              ),
              SizedBox(height: 20.h),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 50.h,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.buttonColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  onPressed: () => _cubit.submitRequest(),
                  child: Text(
                    'employee.sample_submit'.tr(),
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 28.h),

          // Recent requests header
          Text(
            'employee.sample_recent'.tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),

          // Recent request cards
          ...state.recentRequests.map(
            (req) => RequestListCard(
              title: req['name'] ?? '',
              subtitle: 'Blood Type: ${req['blood'] ?? ''}',
              time: req['time'] ?? '',
              status: req['status'] ?? '',
              statusPendingLabel: 'employee.status_pending'.tr(),
              statusCompletedLabel: 'employee.status_completed'.tr(),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
