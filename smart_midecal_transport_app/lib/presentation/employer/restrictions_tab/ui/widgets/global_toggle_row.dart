import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Global on/off toggle row with loading spinner inside the switch.
class GlobalToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final bool isOn;
  final bool isLoading;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  const GlobalToggleRow({
    super.key,
    required this.label,
    required this.description,
    required this.isOn,
    required this.isLoading,
    required this.onChanged,
    this.activeColor = AppColors.error,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isOn
            ? activeColor.withValues(alpha: 0.07)
            : theme.scaffoldBackgroundColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isOn
              ? activeColor.withValues(alpha: 0.35)
              : theme.dividerColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.sp,
                    color: isOn ? activeColor : null,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.labelColor,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          // Status badge
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
            decoration: BoxDecoration(
              color: isOn
                  ? activeColor.withValues(alpha: 0.12)
                  : AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Text(
              isOn ? 'Restricted' : 'Active',
              style: TextStyle(
                color: isOn ? activeColor : AppColors.success,
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 10.w),
          // Toggle switch (with loading overlay)
          SizedBox(
            width: 52.w,
            height: 30.h,
            child: isLoading
                ? Center(
                    child: SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                      ),
                    ),
                  )
                : Switch.adaptive(
                    value: isOn,
                    onChanged: isLoading ? null : onChanged,
                    activeColor: activeColor,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
          ),
        ],
      ),
    );
  }
}
