import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:smart_midecal_transport_app/core/theme/color.dart';

/// Visual chart showing blood bags vs blood samples distribution
class EmployeeRequestChart extends StatelessWidget {
  final int bloodBags;
  final int bloodSamples;
  final String bloodBagsLabel;
  final String samplesLabel;
  final String title;

  const EmployeeRequestChart({
    super.key,
    required this.bloodBags,
    required this.bloodSamples,
    required this.bloodBagsLabel,
    required this.samplesLabel,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = bloodBags + bloodSamples;
    final bagsPercent = total > 0 ? bloodBags / total : 0.0;
    final samplesPercent = total > 0 ? bloodSamples / total : 0.0;

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
          SizedBox(height: 20.h),

          // Blood Bags bar
          _BarItem(
            label: bloodBagsLabel,
            value: bloodBags,
            percent: bagsPercent,
            color: AppColors.error,
            icon: Icons.bloodtype_rounded,
          ),
          SizedBox(height: 16.h),

          // Blood Samples bar
          _BarItem(
            label: samplesLabel,
            value: bloodSamples,
            percent: samplesPercent,
            color: AppColors.info,
            icon: Icons.science_rounded,
          ),
        ],
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String label;
  final int value;
  final double percent;
  final Color color;
  final IconData icon;

  const _BarItem({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 16.sp),
            ),
            SizedBox(width: 8.w),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Text(
              value.toString(),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: percent),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, animatedValue, _) {
              return LinearProgressIndicator(
                value: animatedValue,
                minHeight: 10.h,
                backgroundColor: color.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              );
            },
          ),
        ),
      ],
    );
  }
}
