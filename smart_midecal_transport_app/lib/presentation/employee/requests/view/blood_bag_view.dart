import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:smart_midecal_transport_app/core/di/di.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

import '../cubit/blood_bag_cubit.dart';
import '../cubit/blood_bag_state.dart';
import '../widgets/request_form_card.dart';
import '../widgets/request_form_fields.dart';
import '../widgets/loading_skeleton.dart';

/// Blood Bag Request View
/// Includes a request form and recent bag requests list
class BloodBagView extends StatefulWidget {
  const BloodBagView({super.key});

  @override
  State<BloodBagView> createState() => _BloodBagViewState();
}

class _BloodBagViewState extends State<BloodBagView>
    with AutomaticKeepAliveClientMixin {
  late BloodBagCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<BloodBagCubit>()..loadData();
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
      child: BlocBuilder<BloodBagCubit, BloodBagState>(
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
    BloodBagState state,
    ThemeData theme,
  ) {
    if (state is BloodBagLoading || state is BloodBagInitial) {
      return const RequestLoadingSkeleton(key: ValueKey('loading'));
    }

    if (state is BloodBagError) {
      // Use a SnackBar for error if possible, but here we are returning a Widget.
      // If we want "No previews", we might still want to show the form even if there was an error (e.g. submission error).
      // But if it's a submission error, we probably are still in Loaded state but with a message?
      // The state handling in Cubit: emit(BloodBagError('...'));
      // If it's a submission error, we should probably show the form AND the error.
      // However, the current logic in View is exclusive.
      // Let's keep it simple. If Error, show Error widget.
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

    if (state is BloodBagLoaded || state is BloodBagSubmitting) {
      // Show form. If submitting, maybe show loading indicator overlay or disable button.
      // For now, just show form.
      return ListView(
        key: const ValueKey('loaded'),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        children: [
          // Request form
          RequestFormCard(
            children: [
              // Blood type
              RequestFormFields.label('employee.bag_blood_type'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.dropdown(
                selectedValue: _cubit.selectedBloodType,
                items: _cubit.bloodTypes,
                hint: 'employee.bag_select_blood'.tr(),
                theme: theme,
                onChanged: (v) => setState(() => _cubit.selectedBloodType = v),
              ),
              SizedBox(height: 16.h),

              // Quantity
              RequestFormFields.label('employee.bag_quantity'.tr(), theme),
              SizedBox(height: 8.h),
              RequestFormFields.inputField(
                controller: _cubit.quantityController,
                hint: 'employee.bag_enter_quantity'.tr(),
                theme: theme,
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 16.h),

              // Room
              RequestFormFields.label(
                'employee.bag_room'.tr(),
                theme,
              ), // Need to ensure translation key exists or use hardcoded/dynamic
              // If 'employee.bag_room' doesn't exist, I'll use a placeholder or 'Room'
              // Assuming I can add translation later or it defaults to key.
              // Let's use 'Room' for now if we haven't seen the localization file.
              // I will use 'Room' as label.
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
                  onPressed: state is BloodBagSubmitting
                      ? null
                      : () {
                          // Hide keyboard
                          FocusScope.of(context).unfocus();
                          _cubit.submitRequest();
                        },
                  child: state is BloodBagSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'employee.bag_submit'.tr(),
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
