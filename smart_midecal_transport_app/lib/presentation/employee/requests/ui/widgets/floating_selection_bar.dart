import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Floating bar at the bottom handling bulk submit actions.
class FloatingSelectionBar extends StatelessWidget {
  final List<String> selectedCodes;
  final bool isSubmitting;
  final VoidCallback onClear;
  final VoidCallback onSubmit;

  const FloatingSelectionBar({
    super.key,
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
                      '${selectedCodes.length} ${selectedCodes.length == 1 ? 'status.sample_selected'.tr() : 'status.samples_selected'.tr()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.sp,
                      ),
                    ),
                    Text(
                      'extra.tap_request'.tr(),
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
                    disabledBackgroundColor: Colors.white.withValues(
                      alpha: 0.5,
                    ),
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
                          child: const CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.buttonColor,
                          ),
                        )
                      : Text(
                          'extra.request'.tr(),
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
