import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';
import 'package:smart_midecal_transport_app/presentation/employee/return_flow/domain/entities/return_status_entity.dart';

class ReturnPopupWidget extends StatelessWidget {
  final List<ReturnStatusEntity> samples;
  final bool isSubmitting;
  final VoidCallback onConfirm;

  const ReturnPopupWidget({
    super.key,
    required this.samples,
    required this.isSubmitting,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      child: Positioned.fill(
        child: Material(
          color: Colors.black.withValues(alpha: 0.55),
          child: SafeArea(
            child: Container(
              margin: EdgeInsets.all(16.w),
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDarkColor : AppColors.cardLightColor,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: isDark
                      ? AppColors.cardDarkStrokeColor
                      : AppColors.cardLightStrokeColor,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'return_popup.title'.tr(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'return_popup.subtitle'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.labelColor,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Expanded(
                    child: ListView.separated(
                      itemBuilder: (_, index) {
                        final sample = samples[index];
                        return Container(
                          padding: EdgeInsets.all(12.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.backgroundDarkColor
                                : AppColors.backgroundLightColor,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Text(
                            '${'return_popup.sample_id'.tr()}: ${sample.sampleId} | ${sample.sampleName}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      separatorBuilder: (_, __) => SizedBox(height: 8.h),
                      itemCount: samples.length,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  FilledButton(
                    onPressed: isSubmitting ? null : onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      minimumSize: Size(double.infinity, 48.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'return_popup.confirm_button'.tr(),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
