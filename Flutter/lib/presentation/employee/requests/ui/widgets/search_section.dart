import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/cubit/blood_sample_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/cubit/blood_sample_state.dart';

/// The search input section for patient ID / name.
class SearchSection extends StatelessWidget {
  final BloodSampleCubit cubit;
  final BloodSampleState state;

  const SearchSection({super.key, required this.cubit, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'extra.find_patient_sample'.tr(),
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
            hintText: 'extra.enter_patient_name'.tr(),
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
