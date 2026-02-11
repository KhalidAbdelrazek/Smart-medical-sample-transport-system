import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Reusable recent request list item card
class RequestListCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String status;
  final String statusPendingLabel;
  final String statusCompletedLabel;

  const RequestListCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.statusPendingLabel,
    required this.statusCompletedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPending = status.toLowerCase() == 'pending';
    final statusColor = isPending ? AppColors.warning : AppColors.success;
    final statusText = isPending ? statusPendingLabel : statusCompletedLabel;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              isPending
                  ? Icons.pending_actions_rounded
                  : Icons.check_circle_rounded,
              color: statusColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.labelColor,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14.sp,
                      color: AppColors.labelColor,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.labelColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
