import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../cubit/blood_sample_cubit.dart';
import '../cubit/blood_sample_state.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_form_fields.dart';
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
    _cubit = getIt<BloodSampleCubit>()..loadData();
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

    if (state is BloodSampleLoaded || state is BloodSampleSubmitting) {
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // Request form
          RequestFormCard(
            children: [
              // Patient Identifier
              RequestFormFields.label(
                'employee.sample_patient_name'.tr(), // Or 'Patient Identifier'
                theme,
              ),
              SizedBox(height: 8.h),
              RequestFormFields.inputField(
                controller: _cubit.patientController,
                hint: 'employee.sample_enter_patient'.tr(),
                theme: theme,
              ),
              SizedBox(height: 16.h),

              // Room
              RequestFormFields.label(
                'employee.sample_room'.tr(),
                theme,
              ), // Need to ensure translation key or use default
              SizedBox(height: 8.h),
              RequestFormFields.dropdown(
                selectedValue: _cubit.selectedRoom,
                items: _cubit.rooms,
                hint: 'Select Room',
                theme: theme,
                onChanged: (v) => setState(() => _cubit.selectedRoom = v),
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
                  onPressed: state is BloodSampleSubmitting
                      ? null
                      : () {
                          FocusScope.of(context).unfocus();
                          _cubit.submitRequest();
                        },
                  child: state is BloodSampleSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
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
        ],
      );
    }

    return const SizedBox.shrink();
  }
}
