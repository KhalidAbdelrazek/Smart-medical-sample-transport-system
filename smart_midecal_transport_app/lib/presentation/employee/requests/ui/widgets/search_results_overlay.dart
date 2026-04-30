import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/domain/entities/samples_response_entity.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/cubit/blood_sample_cubit.dart';
import 'package:smart_midecal_transport_app/presentation/employee/requests/ui/widgets/status_chip.dart';

/// Floating card containing the ListView of patient search results.
class SearchResultsOverlay extends StatelessWidget {
  final BloodSampleCubit cubit;
  final ThemeData theme;
  final List<SampleEntity> results;

  const SearchResultsOverlay({
    super.key,
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
                              sample.patientName ?? 'Unknown',
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
                      StatusChip(status: sample.status ?? ''),
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

