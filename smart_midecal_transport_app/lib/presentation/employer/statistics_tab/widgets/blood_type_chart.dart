import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Blood type availability chart widget
/// Displays available blood bags by blood type in a visual grid
class BloodTypeChart extends StatelessWidget {
  final Map<String, int> bloodBagsByType;
  final String title;

  const BloodTypeChart({
    super.key,
    required this.bloodBagsByType,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 16.h),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            mainAxisSpacing: 12.h,
            crossAxisSpacing: 12.w,
            childAspectRatio: 1.0,
            children: bloodBagsByType.entries.map((entry) {
              return _BloodTypeItem(
                bloodType: entry.key,
                count: entry.value,
                color: _getColorForBloodType(entry.key),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Color _getColorForBloodType(String type) {
    switch (type) {
      case 'A+':
        return AppColors.error;
      case 'A-':
        return AppColors.error.withValues(alpha: 0.7);
      case 'B+':
        return AppColors.info;
      case 'B-':
        return AppColors.info.withValues(alpha: 0.7);
      case 'AB+':
        return AppColors.secondary;
      case 'AB-':
        return AppColors.secondary.withValues(alpha: 0.7);
      case 'O+':
        return AppColors.success;
      case 'O-':
        return AppColors.success.withValues(alpha: 0.7);
      default:
        return AppColors.labelColor;
    }
  }
}

class _BloodTypeItem extends StatelessWidget {
  final String bloodType;
  final int count;
  final Color color;

  const _BloodTypeItem({
    required this.bloodType,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            bloodType,
            style: TextStyle(
              color: color,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            count.toString(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
