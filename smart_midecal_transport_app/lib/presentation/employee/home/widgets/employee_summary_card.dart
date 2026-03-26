import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Request summary card showing pending vs completed requests
class EmployeeSummaryCard extends StatelessWidget {
  final String title;
  final int pendingCount;
  final int completedCount;
  final String pendingLabel;
  final String completedLabel;

  const EmployeeSummaryCard({
    super.key,
    required this.title,
    required this.pendingCount,
    required this.completedCount,
    required this.pendingLabel,
    required this.completedLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = pendingCount + completedCount;
    final completedPercent = total > 0 ? (completedCount / total) : 0.0;

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

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completedPercent),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, _) {
                return LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 12.h,
                  backgroundColor: AppColors.warning.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.success,
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 16.h),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: pendingLabel,
                  value: pendingCount.toString(),
                  color: AppColors.warning,
                  icon: Icons.pending_actions_rounded,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _StatItem(
                  label: completedLabel,
                  value: completedCount.toString(),
                  color: AppColors.success,
                  icon: Icons.check_circle_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color, size: 18.sp),
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.labelColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
